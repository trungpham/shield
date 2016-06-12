defmodule Shield.SessionAuth do
  @moduledoc """
  Shield Strategy to check session based authencations and assigning
  resource owner.
  """

  import Plug.Conn, only: [fetch_session: 1, get_session: 2]

  @authorizations Application.get_env(:shield, :authorizations)
  @session_auth Map.get(@authorizations, :session)

  @doc """
  Finds resource owner using configured session keys
  """
  def authenticate(conn) do
    if @session_auth, do: authenticate(conn, @session_auth)
  end

  defp authenticate(conn, session_auth) do
    Enum.find_value(session_auth, fn {key, module} ->
      session_value = conn |> fetch_session |> get_session(key)
      if session_value do
        module.authenticate(session_value)
      end
    end)
  end
end
