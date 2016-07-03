defmodule Shield.ClientController do
  use Shield.Web, :controller

  @repo Application.get_env(:authable, :repo)
  @client Application.get_env(:authable, :client)
  @views Application.get_env(:shield, :views)

  plug :scrub_params, "client" when action in [:create, :update]
  plug Authable.Plug.Authenticate, [scopes: ~w(session)]

  def index(conn, _params) do
    query = (from c in @client,
             where: c.user_id == ^conn.assigns[:current_user].id)
    clients = @repo.all(query)
    render(conn, @views[:client], "index.json", clients: clients)
  end

  def create(conn, %{"client" => client_params}) do
    client_params = Map.put(client_params, "user_id",
                            conn.assigns[:current_user].id)
    changeset = @client.changeset(%@client{}, client_params)

    case @repo.insert(changeset) do
      {:ok, client} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", client_path(conn, :show, client))
        |> render(@views[:client], "show.json", client: client)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset],  "error.json",
                  changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    case @repo.get_by(@client, id: id,
                       user_id: conn.assigns[:current_user].id) do
      nil    ->
        conn
        |> put_status(:not_found)
        |> render(@views[:error], "404.json")
      client ->
        conn
        |> render(@views[:client], "show.json", client: client)
    end
  end

  def update(conn, %{"id" => id, "client" => client_params}) do
    client = @repo.get_by!(@client, id: id,
                           user_id: conn.assigns[:current_user].id)
    changeset = @client.changeset(client, client_params)

    case @repo.update(changeset) do
      {:ok, client} ->
        conn
        |> put_status(:ok)
        |> render(@views[:client], "show.json", client: client)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json",
                  changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    client = @repo.get_by!(@client, id: id,
                           user_id: conn.assigns[:current_user].id)
    @repo.delete!(client)

    send_resp(conn, :no_content, "")
  end
end
