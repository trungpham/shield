defmodule Shield.HeaderAuthTest do
  use Shield.ConnCase
  import Shield.Factory

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  test "returns user model when authenticates with Basic Authentication using valid data", %{conn: conn} do
    user = insert(:user)
    basic_auth_token = Base.encode64("#{user.email}:12345678")
    conn = conn |> put_req_header("authorization", "Basic #{basic_auth_token}")
    assert user == Shield.HeaderAuth.authenticate(conn)
  end

  test "returns nil when fails to authenticate with Basic Authentication using invalid data", %{conn: conn} do
    conn = conn |> put_req_header("authorization", "Basic 1231412123")
    assert is_nil(Shield.HeaderAuth.authenticate(conn))
  end

  test "returns user model when authenticates with Bearer Authentication using valid data", %{conn: conn} do
    user = insert(:user)
    client = insert(:client, user: user)
    token = insert(:access_token, user: user, details: %{client_id: client.id})
    conn = conn |> put_req_header("authorization", "Bearer #{token.value}")
    assert user == Shield.HeaderAuth.authenticate(conn)
  end

  test "returns nil when fails to authenticate with Bearer Authentication using invalid data", %{conn: conn} do
    conn = conn |> put_req_header("authorization", "Bearer unKnoWn")
    assert is_nil(Shield.HeaderAuth.authenticate(conn))
  end

  test "returns user model when authenticates with X-API-TOKEN using valid data", %{conn: conn} do
    user = insert(:user)
    client = insert(:client, user: user)
    token = insert(:access_token, user: user, details: %{client_id: client.id})
    conn = conn |> put_req_header("x-api-token", "#{token.value}")
    assert user == Shield.HeaderAuth.authenticate(conn)
  end

  test "returns nil when fails to authenticates with X-API-TOKEN using invalid data", %{conn: conn} do
    conn = conn |> put_req_header("x-api-token", "unKnoWn")
    assert is_nil(Shield.HeaderAuth.authenticate(conn))
  end
end
