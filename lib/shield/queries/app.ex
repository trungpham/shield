defmodule Shield.Query.App do
  @moduledoc """
  Query builder for Authable.App Model
  """

  import Ecto.Query

  @app Application.get_env(:authable, :app)

  @doc """
  Query for App list with user
  """
  def user_apps(user) do
    (from a in @app,
      preload: [:client],
      where: a.user_id == ^user.id)
  end

  @doc """
  Query for App with user
  """
  def user_app(user, id) do
    (from a in @app,
      preload: [:client],
      where: a.id == ^id and a.user_id == ^user.id,
      limit: 1)
  end
end
