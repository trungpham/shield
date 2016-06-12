defmodule Shield.QueryParamsAuthTest do
  use Shield.ConnCase
  import Shield.Factory

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  test "returns user model when authenticates with access_token query string using valid data", %{conn: conn} do
    user = insert(:user)
    client = insert(:client, user: user)
    token = insert(:access_token, user: user, details: %{client_id: client.id})
    params = %{"access_token" => token.value}
    conn = conn |> fetch_query_params |> Map.put(:query_params, params)
    assert user == Shield.QueryParamsAuth.authenticate(conn)
  end

  test "returns nil when fails to authenticates with access_token query string using invalid data", %{conn: conn} do
    params = %{"access_token" => "invalid"}
    conn = conn |> fetch_query_params |> Map.put(:query_params, params)
    assert is_nil(Shield.QueryParamsAuth.authenticate(conn))
  end
end
