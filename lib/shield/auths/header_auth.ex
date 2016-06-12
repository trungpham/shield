defmodule Shield.HeaderAuth do
  @moduledoc """
  Shield Strategy to check header based authencations and assigning resource
  owner.
  """

  import Plug.Conn, only: [get_req_header: 2]

  @authorizations Application.get_env(:shield, :authorizations)
  @header_auth Map.get(@authorizations, :headers)

  @doc """
  Finds resource owner using configured headers
  """
  def authenticate(conn) do
    if @header_auth, do: authenticate(conn, @header_auth)
  end

  defp authenticate(conn, header_auth) do
    Enum.find_value(header_auth, fn {key, auth_info} ->
      case List.first(get_req_header(conn, key)) do
        nil -> nil
        header_val -> authenticate_via_header(header_val, auth_info)
      end
    end)
  end

  defp authenticate_via_header(header_val, auth_info) do
    if is_map(auth_info) do
      authenticate_via_splitted_headers(header_val, auth_info)
    else
      auth_info.authenticate(header_val)
    end
  end

  defp authenticate_via_splitted_headers(header_val, auth_info) do
    [auth_type, auth_token] = header_val |> String.split(" ", trim: true)
    auth_info[auth_type].authenticate(auth_token)
  end
end
