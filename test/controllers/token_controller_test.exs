defmodule Shield.TokenControllerTest do
  use Shield.ConnCase
  import Shield.Factory

  setup %{conn: conn} do
    user1 = insert(:user)
    user2 = insert(:user)

    client1 = insert(:client, user: user1)
    client2 = insert(:client, user: user2)

    token1 = insert(:access_token, user: user2, details: %{
      client_id: client1.id, scope: "read"})
    token2 = insert(:access_token, user: user2, details: %{
      client_id: client2.id, scope: "read"})
    token3 = insert(:authorization_code, user: user2, details: %{
      client_id: client1.id, scope: "read", redirect_uri: client1.redirect_uri})
    token4 = insert(:refresh_token, user: user2, details: %{
      client_id: client1.id, scope: "read"})

     {:ok, conn: put_req_header(conn, "accept", "application/json"),
     token: token1,
     another_client_token: token2,
     authorization_code_token: token3,
     refresh_token: token4,
     client: client1,
     user: user2}
  end

  test "shows chosen resource", %{conn: conn, token: token, client: client} do
    conn = get conn, token_path(conn, :show, token.value),
      client_id: client.id, client_secret: client.secret

    assert json_response(conn, 200)["token"] == %{
      "details" => %{
        "client_id" => client.id,
        "scope" => "read"},
      "expires_at" => token.expires_at,
      "name" => token.name,
      "value" => token.value
    }
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn, client: client} do
    conn = get(conn, token_path(conn, :show, "invalid token"),
      client_id: client.id, client_secret: client.secret)
    assert response(conn, 404)
  end

  test "does not show resource and instead throw error when id not belongs to current user", %{conn: conn, client: client, another_client_token: token} do
    conn = get(conn, token_path(conn, :show, token.value),
      client_id: client.id, client_secret: client.secret)
    assert response(conn, 404)
  end

  test "authorize with grant_type authorization_code", %{conn: conn, client: client, authorization_code_token: token} do
    insert(:app, user_id: token.user_id, client_id: client.id)
    params = %{"token" => %{"grant_type" => "authorization_code",
               "client_id" => client.id, "client_secret" => client.secret,
               "code" => token.value, "redirect_uri" => client.redirect_uri}}
    conn = post(conn, token_path(conn, :create), params)
    assert response(conn, 201)
  end

  test "authorize with grant_type password", %{conn: conn, user: user, client: client} do
    params = %{"token" => %{"grant_type" => "password",
               "client_id" => client.id, "email" => user.email,
               "password" => "12345678", "scope" => "read"}}
    conn = post(conn, token_path(conn, :create), params)
    assert response(conn, 201)
  end

  test "authorize with grant_type client_credentials", %{conn: conn, client: client}  do
    params = %{"token" => %{"grant_type" => "client_credentials",
               "client_id" => client.id, "client_secret" => client.secret}}
    conn = post(conn, token_path(conn, :create), params)
    assert response(conn, 201)
  end

  test "authorize with grant_type refresh_token", %{conn: conn, client: client, refresh_token: token} do
    insert(:app, user_id: token.user_id, client_id: client.id)
    params = %{"token" => %{"grant_type" => "refresh_token",
               "client_id" => client.id, "client_secret" => client.secret,
               "refresh_token" => token.value}}
    conn = post(conn, token_path(conn, :create), params)
    assert response(conn, 201)
  end
end
