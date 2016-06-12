defmodule Shield.QueryParamsAuth do
  @moduledoc """
  Shield Strategy to check query params based authencations and assigning
  resource owner.
  """

  @authorizations Application.get_env(:shield, :authorizations)
  @query_params_auth Map.get(@authorizations, :query_params)

  @doc """
  Finds resource owner using configured query params
  """
  def authenticate(conn) do
    if @query_params_auth,
      do: authenticate(@query_params_auth, conn.query_params)
  end

  defp authenticate(query_params_auth, params) do
    Enum.find_value(query_params_auth, fn {key, module} ->
      if Map.has_key?(params, key) do
        module.authenticate(params)
      end
    end)
  end
end
