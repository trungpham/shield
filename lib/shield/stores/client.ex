defmodule Shield.Store.Client do
  @moduledoc """
  Client data fetcher
  """

  alias Shield.Query.Client, as: ClientQuery

  @client Application.get_env(:authable, :client)
  @repo Application.get_env(:authable, :repo)

  @doc """
  Fetches the user's clients from DB
  """
  def user_clients(user) do
    user
    |> ClientQuery.user_clients
    |> @repo.all()
  end

  @doc """
  Fetches the user's client from DB
  """
  def user_client(user, id) do
    user
    |> ClientQuery.user_client(id)
    |> @repo.get_by([])
  end

  def create_user_client(user, client_params) do
    client_params = Map.put(client_params, "user_id", user.id)
    changeset = @client.changeset(%@client{}, client_params)
    case @repo.insert(changeset) do
      {:ok, client} ->
        {:ok, client}
      {:error, changeset} ->
        {:error, {:unprocessable_entity, changeset}}
    end
  end

  @doc """
  Updates the user's client
  """
  def update_user_client(user, id, client_params) do
    client = user_client(user, id)
    client_params = Map.put(client_params, "user_id", user.id)
    changeset = @client.changeset(client, client_params)
    case @repo.update(changeset) do
      {:ok, client} ->
        {:ok, client}
      {:error, changeset} ->
        {:error, {:unprocessable_entity, changeset}}
    end
  end

  @doc """
  Deletes the user's client
  """
  def delete_user_client(user, id) do
    client = user_client(user, id)
    @repo.delete!(client)
  end

  @doc """
  Fetches the client from DB for given id
  """
  def find(id) do
    @repo.get(@client, id)
  end
end
