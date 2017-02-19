defmodule Shield.Query.Client do
  @moduledoc """
  Query builder for Authable.Client Model
  """

  import Ecto.Query

  @client Application.get_env(:authable, :client)

  @doc """
  Query for Client list with user
  """
  def user_clients(user) do
    (from c in @client,
      where: c.user_id == ^user.id)
  end

  @doc """
  Query for Client with user
  """
  def user_client(user, id) do
    (from c in @client,
      where: c.id == ^id and c.user_id == ^user.id,
      limit: 1)
  end
end
