defmodule Shield.Store.Token do
  @moduledoc """
  Token data fetcher
  """

  @client Application.get_env(:authable, :client)
  @token_store Application.get_env(:authable, :token_store)
  @repo Application.get_env(:authable, :repo)

  @doc """
  Fetches the client's token from DB
  """
  def client_token(%{"id" => _, "client_id" => _, "client_secret" => _} = params) do
    params
    |> find_token()
    |> find_client()
    |> validate_client_token_ownership()
  end

  defp find_token(%{"id" => token_value} = params) do
    case @repo.get_by(@token_store, value: token_value) do
      nil ->
        {:error, {:not_found, %{id: ["Invalid token identifier!"]}}}
      token ->
        {:ok, Map.put(params, "token", token)}
    end
  end

  defp find_client({:ok, %{"client_id" => id, "client_secret" => secret} = params}) do
    case @repo.get_by(@client, id: id, secret: secret) do
      nil ->
        {:error, {:not_found, %{client_id: ["Invalid client identifier!"]}}}
      client ->
        {:ok, Map.put(params, "client", client)}
    end
  end
  defp find_client({:error, params}),
    do: {:error, params}

  defp validate_client_token_ownership({:ok, %{"token" => token, "client_id" => client_id} = params}) do
    if Map.get(token.details, "client_id", "") == client_id do
      {:ok, params}
    else
      {:error, {:not_found, %{id: ["Invalid client identifier!"]}}}
    end
  end
  defp validate_client_token_ownership({:error, params}),
    do: {:error, params}
end
