defmodule Shield.AppController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Authable.OAuth2, as: OAuth2

  @repo Application.get_env(:authable, :repo)
  @app Application.get_env(:authable, :app)
  @token_store Application.get_env(:authable, :token_store)
  @client Application.get_env(:authable, :client)
  @views Application.get_env(:shield, :views)
  @renderer Application.get_env(:authable, :renderer)

  plug :before_app_authorize when action in [:authorize]
  plug :before_app_delete when action in [:delete]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read)] when action in [:index, :show]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:authorize, :delete]
  plug Shield.Arm.Confirmable, [enabled: Application.get_env(:shield, :confirmable)]

  # GET /apps
  def index(conn, _params) do
    query = (from a in @app,
             preload: [:client],
             where: a.user_id == ^conn.assigns[:current_user].id)
    apps = @repo.all(query)
    render(conn, @views[:app], "index.json", apps: apps)
  end

  # GET /apps/:id
  def show(conn, %{"id" => id}) do
    query = (from a in @app,
             preload: [:client],
             where: a.id == ^id and
                    a.user_id == ^conn.assigns[:current_user].id, limit: 1)
    app = List.first(@repo.all(query))
    if is_nil(app) do
      conn
      |> put_status(:not_found)
      |> render(@views[:error], "404.json")
    else
      render(conn, @views[:app], "show.json", app: app)
    end
  end

  # POST /apps/authorize
  def authorize(conn, %{"app" => params}) do
    result = OAuth2.authorize_app(conn.assigns[:current_user], params)
    case result do
    {:error, errors, http_status_code} ->
      conn
      |> @hooks.after_app_authorize_failure(errors, http_status_code)
      |> @renderer.render(http_status_code, %{errors: errors})
    app ->
      changeset = @token_store.authorization_code_changeset(%@token_store{}, %{
        user_id: conn.assigns[:current_user].id,
        details: %{
          client_id: params["client_id"],
          redirect_uri: params["redirect_uri"],
          scope: app.scope
        }
      })
      case @repo.insert(changeset) do
      {:ok, token} ->
        conn
        |> @hooks.after_app_authorize_success(token)
        |> put_status(:created)
        |> render(@views[:token], "show.json", token: token)
      {:error, errors} ->
        conn
        |> @hooks.after_app_authorize_failure(errors, :unprocessable_entity)
        |> put_status(:unprocessable_entity)
        |> render(@views[:error], "422.json")
      end
    end
  end

  # DELETE /apps/:id
  def delete(conn, %{"id" => id}) do
    OAuth2.revoke_app_authorization(conn.assigns[:current_user], %{"id" => id})
    conn
    |> @hooks.after_app_delete
    |> send_resp(:no_content, "")
  end
end
