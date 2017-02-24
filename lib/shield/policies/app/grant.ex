defmodule Shield.Policy.App.Grant do
  @moduledoc """
  App.Grant policy
  """

  alias Authable.OAuth2

  @doc """
  Runs app access grant for given params
  - Grants access to app
  """
  def process(%{"user" => user} = params) do
    case OAuth2.grant_app_authorization(user, params) do
      {:error, errors, http_status_code} ->
        {:error, {http_status_code, errors}}
      {:error, changeset} ->
        {:error, {:unprocessable_entity, changeset}}
      res ->
        {:ok, res}
    end
  end
end
