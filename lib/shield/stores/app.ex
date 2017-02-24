defmodule Shield.Store.App do
  @moduledoc """
  App data fetcher
  """

  alias Shield.Query.App, as: AppQuery

  @repo Application.get_env(:authable, :repo)

  @doc """
  Fetches the user's apps from DB
  """
  def user_apps(user) do
    user
    |> AppQuery.user_apps()
    |> @repo.all([])
  end

  @doc """
  Fetches the user's app from DB
  """
  def user_app(user, id) do
    user
    |> AppQuery.user_app(id)
    |> @repo.get_by([])
  end
end
