defmodule Shield.AppController do
  use Shield.Web, :controller
  use Shield.Authorization
  alias Authable.OAuth2, as: OAuth2

  @repo Application.get_env(:authable, :repo)
  @app Application.get_env(:authable, :app)
  @token_store Application.get_env(:authable, :token_store)
  @client Application.get_env(:authable, :client)

  @views Application.get_env(:shield, :views)

  plug :authenticate!

  def index(conn, _params) do
    query = (from a in @app,
             preload: [:client],
             where: a.user_id == ^conn.assigns[:current_user].id)
    apps = @repo.all(query)
    render(conn, @views[:app], "index.json", apps: apps)
  end

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

  def authorize(conn, %{"app" => params}) do
    app = OAuth2.authorize_app(conn.assigns[:current_user], params)
    if is_nil(app) do
      conn
      |> put_status(:unprocessable_entity)
      |> render(@views[:error], "422.json")
    else
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
          conn |> put_status(:created)
               |> render(@views[:token], "show.json", token: token)
        {:error, _} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(@views[:error], "422.json")
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    OAuth2.revoke_app_authorization(conn.assigns[:current_user], %{"id" => id})
    send_resp(conn, :no_content, "")
  end
end
