defmodule Shield.AppController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Authable.OAuth2, as: OAuth2
  alias Shield.Query.App, as: AppQuery

  @repo Application.get_env(:authable, :repo)
  @app Application.get_env(:authable, :app)
  @token_store Application.get_env(:authable, :token_store)
  @views Application.get_env(:shield, :views)
  @renderer Application.get_env(:authable, :renderer)

  plug :before_app_authorize when action in [:authorize]
  plug :before_app_delete when action in [:delete]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read)] when action in [:index, :show]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:authorize, :delete]
  plug Shield.Arm.Confirmable, [enabled: Application.get_env(:shield, :confirmable)]

  # GET /apps
  def index(conn, _params) do
    apps =
      conn.assigns[:current_user]
      |> AppQuery.user_apps()
      |> @repo.all()

    render(conn, @views[:app], "index.json", apps: apps)
  end

  # GET /apps/:id
  def show(conn, %{"id" => id}) do
    app =
      conn.assigns[:current_user]
      |> AppQuery.user_app(id)
      |> @repo.get_by([])

    case app do
      nil ->
        render(put_status(conn, :not_found), @views[:error], "404.json")
      app ->
        render(conn, @views[:app], "show.json", app: app)
    end
  end

  # POST /apps/authorize
  def authorize(conn, %{"app" => params}) do
    result = OAuth2.grant_app_authorization(conn.assigns[:current_user], params)
    case result do
      {:error, errors, http_status_code} ->
        conn
        |> @hooks.after_app_authorize_failure(errors, http_status_code)
        |> @renderer.render(http_status_code, %{errors: errors})
      %{"token" => token} ->
        conn
        |> @hooks.after_app_authorize_success(token)
        |> put_status(:created)
        |> render(@views[:token], "show.json", token: token)
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
