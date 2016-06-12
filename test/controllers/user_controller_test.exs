defmodule Shield.UserControllerTest do
  use Shield.ConnCase
  import Shield.Factory

  @repo Application.get_env(:authable, :repo)
  @token_store Application.get_env(:authable, :token_store)

  defp sign_conn(conn) do
    conn |> put_req_cookie("_shield_key",
      "g3QAAAABbQAAAA1zZXNzaW9uX3Rva2VubQAAAAxzdDEyMzQ1Njc4OTA=##FttLPDULU4rx55O3DKmAF-Putjw=")
  end

  setup %{conn: conn} do
    user = insert(:user, email: "foo@bar.com")
    token = insert(:session_token, value: "st1234567890", user_id: user.id)
    {:ok,
      conn: conn
            |> put_req_header("accept", "application/json"),
      token_value: token.value
    }
  end

  test "a GET request to /me shows current user information", %{conn: conn} do
    conn = conn
           |> sign_conn
    conn = conn |> get(user_path(conn, :me))
    assert json_response(conn, 201)["user"]
  end

  test "a GET request to /me gives unauthorized error", %{conn: conn} do
    conn = get conn, user_path(conn, :me)
    assert response(conn, 401)
  end

  test "a POST request to /register with valid email and password", %{conn: conn} do
    params = %{email: "loo@bar.com", password: "12345678"}
    conn = post conn, user_path(conn, :register), user: params
    user = json_response(conn, 201)["user"]
    assert user
    assert user["email"]
    refute user["password"]
  end

  test "a POST request to /register with valid email and password and session", %{conn: conn} do
    params = %{email: "loo@bar.com", password: "12345678"}
    conn = conn
           |> sign_conn
           |> post(user_path(conn, :register), user: params)
    assert response(conn, 422)
  end

  test "a POST request to /register with missing password", %{conn: conn} do
    params = %{email: "loo@foobar.com", password: ""}
    conn = post conn, user_path(conn, :register), user: params
    assert response(conn, 422)
  end

  test "a POST request to /register with malformed email", %{conn: conn} do
    params = %{email: "foonoatbar.com", password: "12345678"}
    conn = post conn, user_path(conn, :register), user: params
    assert response(conn, 422)
  end

  test "a POST request to /login with valid email & password", %{conn: conn} do
    params = %{email: "foo@bar.com", password: "12345678"}
    conn = post conn, user_path(conn, :login), user: params
    user = json_response(conn, 201)["user"]
    token_value = conn |> fetch_session |> get_session("session_token")
    assert token_value
    assert @repo.get_by! @token_store, value: token_value, name: "session_token"
    assert user
    assert user["email"]
    refute user["password"]
  end

  test "a POST request to /login with valid email & wrong password", %{conn: conn} do
    params = %{email: "foo@bar.com", password: "87654321"}
    conn = post conn, user_path(conn, :login), user: params
    assert response(conn, 401)
  end

  test "a POST request to /login with non-existent email & password", %{conn: conn} do
    params = %{email: "nonexistent@bar.com", password: "12345678"}
    conn = post conn, user_path(conn, :login), user: params
    assert response(conn, 401)
  end

  test "a DELETE request to /logout with a valid session", %{conn: conn} do
    conn = conn
           |> sign_conn
           |> delete(user_path(conn, :logout))
    assert response(conn, 204)
  end

  test "a DELETE request to /logout without a valid session", %{conn: conn} do
    conn = delete conn, user_path(conn, :logout)
    assert response(conn, 401)
  end
end