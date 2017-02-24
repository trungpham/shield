defmodule Shield.Policy.User.Logout do
  @moduledoc """
  User.Logout policy
  """

  @repo Application.get_env(:authable, :repo)
  @token_store Application.get_env(:authable, :token_store)

  @doc """
  Runs logout process for given params
  - Deletes session token
  """
  def process(params) do
    params
    |> delete_session_token()
  end

  defp delete_session_token(%{"token_value" => token_value}) do
    token = @repo.get_by!(@token_store, name: "session_token",
      value: token_value)
    @repo.delete!(token)
  end
end
