defmodule Shield.Policy.Token.Authorize do
  @moduledoc """
  Token.Authorize policy
  """

  alias Authable.OAuth2

  @doc """
  Runs token authorization with given params
  - Authorize and return token
  """
  def process(params) do
    case OAuth2.authorize(params) do
      {:error, errors, http_status_code} ->
        {:error, {http_status_code, errors}}
      {:error, changeset} ->
        {:error, {:unprocessable_entity, changeset}}
      token ->
        {:ok, token}
    end
  end
end
