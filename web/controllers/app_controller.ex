defmodule Shield.AppController do
  use Shield.Web, :controller
  alias Authable.OAuth2, as: OAuth2
  alias Shield.Store.App, as: AppStore
  alias Shield.Policy.App.Grant, as: GrantPolicy

  @views Application.get_env(:shield, :views)
  @renderer Application.get_env(:authable, :renderer)
  @hooks Application.get_env(:shield, :hooks)

  plug Authable.Plug.Authenticate, [scopes: ~w(session read)] when action in [:index, :show]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:authorize, :delete]
  plug Shield.Arm.Confirmable, [enabled: Application.get_env(:shield, :confirmable)]

  # GET /apps
  def index(conn, _params) do
    apps = AppStore.user_apps(conn.assigns[:current_user])
    render(conn, @views[:app], "index.json", apps: apps)
  end

  # GET /apps/:id
  def show(conn, %{"id" => id}) do
    app = AppStore.user_app(conn.assigns[:current_user], id)

    case app do
      nil ->
        render(put_status(conn, :not_found), @views[:error], "404.json")
      app ->
        render(conn, @views[:app], "show.json", app: app)
    end
  end

  # POST /apps/authorize
  def authorize(conn, %{"app" => app_params} = params) do
    conn = @hooks.before_app_authorize(conn, params)
    params = Map.put(app_params, "user", conn.assigns[:current_user])
    case GrantPolicy.process(params) do
      {:ok, %{"token" => token} = res} ->
        conn
        |> @hooks.after_app_authorize_success({app_params, res})
        |> put_status(:created)
        |> render(@views[:token], "show.json", token: token)
      {:error, {http_status_code, errors} = res} ->
        conn
        |> @hooks.after_app_authorize_failure({app_params, res})
        |> @renderer.render(http_status_code, %{errors: errors})
    end
  end

  # DELETE /apps/:id
  def delete(conn, %{"id" => id} = params) do
    conn = @hooks.before_app_delete(conn, params)
    OAuth2.revoke_app_authorization(conn.assigns[:current_user], %{"id" => id})

    conn
    |> @hooks.after_app_delete(params)
    |> send_resp(:no_content, "")
  end
end
