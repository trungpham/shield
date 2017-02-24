defmodule Shield.ClientController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Shield.Store.Client, as: ClientStore

  @views Application.get_env(:shield, :views)
  @hooks Application.get_env(:shield, :hooks)

  plug :scrub_params, "client" when action in [:create, :update]
  plug :before_client_create when action in [:create]
  plug :before_client_update when action in [:update]
  plug :before_client_delete when action in [:delete]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read)] when action in [:index]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:create, :update, :delete]
  plug Shield.Arm.Confirmable, [enabled: Application.get_env(:shield, :confirmable)]

  # GET /clients
  def index(conn, _params) do
    clients = ClientStore.user_clients(conn.assigns[:current_user])
    render(conn, @views[:client], "index.json", clients: clients)
  end

  # POST /clients
  def create(conn, %{"client" => client_params}) do
    user = conn.assigns[:current_user]
    case ClientStore.create_user_client(user, client_params) do
      {:ok, client} ->
        conn
        |> @hooks.after_client_create_success({client_params, client})
        |> put_status(:created)
        |> put_resp_header("location", client_path(conn, :show, client))
        |> render(@views[:client], "show.json", client: client)
      {:error, {http_status_code, errors} = res} ->
        conn
        |> @hooks.after_client_create_failure({client_params, res})
        |> put_status(http_status_code)
        |> render(@views[:changeset],  "error.json", changeset: errors)
    end
  end

  # GET /clients/:id
  def show(conn, %{"id" => id}) do
    case ClientStore.find(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(@views[:error], "404.json")
      client ->
        user = fetch_current_user(conn)
        is_owner = user && user.id == client.user_id
        render(conn, @views[:client], "show.json", client: client,
          is_owner: is_owner)
    end
  end

  # PUT /clients/:id
  def update(conn, %{"id" => id, "client" => client_params}) do
    user = conn.assigns[:current_user]
    case ClientStore.update_user_client(user, id, client_params) do
      {:ok, client} ->
        conn
        |> @hooks.after_client_update_success({client_params, client})
        |> put_status(:ok)
        |> render(@views[:client], "show.json", client: client)
      {:error, {http_status_code, errors} = res} ->
        conn
        |> @hooks.after_client_update_failure({client_params, res})
        |> put_status(http_status_code)
        |> render(@views[:changeset], "error.json", changeset: errors)
    end
  end

  # DELETE /clients/:id
  def delete(conn, %{"id" => id} = app_params) do
    ClientStore.delete_user_client(conn.assigns[:current_user], id)

    conn
    |> @hooks.after_client_delete(app_params)
    |> send_resp(:no_content, "")
  end

  defp fetch_current_user(conn) do
    case Authable.Helper.authorize_for_resource(conn, ~w(session)) do
      {:ok, user} -> user
      _ -> nil
    end
  end
end
