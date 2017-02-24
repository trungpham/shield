defmodule Shield.UserControllerTest do
  use Shield.ConnCase
  import Shield.Factory
  alias Shield.Arm.OneTimePassword
  alias Comeonin.Otp

  @repo Application.get_env(:authable, :repo)
  @token_store Application.get_env(:authable, :token_store)

  defp sign_conn(conn) do
    put_req_cookie(conn, "_shield_key",
      "g3QAAAABbQAAAA1zZXNzaW9uX3Rva2VubQAAAAxzdDEyMzQ1Njc4OTA=##FttLPDULU4rx55O3DKmAF-Putjw=")
  end

  setup %{conn: conn} do
    Application.put_env(:shield, :confirmable, false)
    Application.put_env(:shield, :otp_check, false)

    user = insert(:user, email: "foo@bar.com", settings: %{"confirmed" => false, "otp_enabled" => false})
    token = insert(:session_token, value: "st1234567890", user_id: user.id)
    {:ok,
      conn: put_req_header(conn, "accept", "application/json"),
      token_value: token.value,
      user: user
    }
  end

  test "a GET request to /me shows current user information", %{conn: conn} do
    conn = sign_conn(conn)
    conn = get(conn, user_path(conn, :me))
    assert json_response(conn, 200)["user"]
  end

  test "a GET request without auth to /me gives forbidden error", %{conn: conn} do
    conn = get(conn, user_path(conn, :me))
    assert response(conn, 403)
  end

  test "a GET request to /confirm with a valid token", %{conn: conn, user: user} do
    Application.put_env(:shield, :confirmable, true)
    token = insert(:confirmation_token, user_id: user.id)
    params = %{"confirmation_token" => token.value}

    conn = get(conn, user_path(conn, :confirm), params)
    assert response(conn, 200)
  end

  test "a GET request to /confirm with invalid token", %{conn: conn} do
    params = %{"confirmation_token" => "invalidtoken"}
    conn = get(conn, user_path(conn, :confirm), params)
    assert response(conn, 403)
  end

  test "a POST request to /reset_password with a valid token", %{conn: conn, user: user} do
    token = insert(:reset_token, user_id: user.id)
    params = %{"password" => "abcd1234", "reset_token" => token.value}
    conn = post(conn, user_path(conn, :reset_password), user: params)
    assert response(conn, 200)
  end

  test "a POST request to /reset_password with a valid token and ensure that is not valid anymore", %{conn: conn, user: user} do
    token = insert(:reset_token, user_id: user.id)
    params = %{"password" => "abcd1234", "reset_token" => token.value}
    conn = post(conn, user_path(conn, :reset_password), user: params)
    assert response(conn, 200)
    conn = post(conn, user_path(conn, :reset_password), user: params)
    assert response(conn, 403)
  end

  test "a POST request to /reset_password with invalid token", %{conn: conn} do
    params = %{"password" => "abcd1234", "reset_token" => "invalidtoken"}
    conn = post(conn, user_path(conn, :reset_password), user: params)
    assert response(conn, 403)
  end

  test "a POST request to /reset_password with invalid new password", %{conn: conn, user: user} do
    token = insert(:reset_token, user_id: user.id)
    params = %{"password" => "1234567", "reset_token" => token.value}
    conn = post(conn, user_path(conn, :reset_password), user: params)
    assert response(conn, 422)
  end

  test "a POST request to /change_password with a correct current password", %{conn: conn} do
    params = %{"password" => "abcd1234", "old_password" => "12345678"}
    conn =
      conn
      |> sign_conn()
      |> post(user_path(conn, :change_password), user: params)
    assert response(conn, 200)
  end

  test "a POST request to /change_password with wrong current password", %{conn: conn} do
    params = %{"password" => "abcd1234", "old_password" => "wrongpass"}
    conn =
      conn
      |> sign_conn()
      |> post(user_path(conn, :change_password), user: params)
    assert response(conn, 403)
  end

  test "a POST request to /change_password with invalid new password", %{conn: conn} do
    params = %{"password" => "1234567", "old_password" => "12345678"}
    conn =
      conn
      |> sign_conn()
      |> post(user_path(conn, :change_password), user: params)
    assert response(conn, 422)
  end

  test "a POST request to /register with valid email and password", %{conn: conn} do
    params = %{"email" => "loo@bar.com", "password" => "12345678"}
    conn = post conn, user_path(conn, :register), user: params
    user = json_response(conn, 201)["user"]
    assert user
    assert user["email"]
    refute user["password"]
  end

  test "a POST request to /register with valid email and password and session", %{conn: conn} do
    params = %{"email" => "loo@bar.com", "password" => "12345678"}
    conn =
      conn
      |> sign_conn()
      |> post(user_path(conn, :register), user: params)
    assert response(conn, 400)
  end

  test "a POST request to /register with missing password", %{conn: conn} do
    params = %{"email" => "loo@foobar.com", "password" => ""}
    conn = post conn, user_path(conn, :register), user: params
    assert response(conn, 422)
  end

  test "a POST request to /register with malformed email", %{conn: conn} do
    params = %{"email" => "foonoatbar.com", "password" => "12345678"}
    conn = post conn, user_path(conn, :register), user: params
    assert response(conn, 422)
  end

  test "a POST request to /login with valid email & password", %{conn: conn} do
    params = %{"email" => "foo@bar.com", "password" => "12345678"}
    conn = post conn, user_path(conn, :login), user: params
    user = json_response(conn, 201)["user"]
    token_value = conn |> fetch_session |> get_session("session_token")
    assert token_value
    assert @repo.get_by! @token_store, value: token_value, name: "session_token"
    assert user
    assert user["email"]
    refute user["password"]
  end

  test "a POST request to /login with valid email & password when one time password enabled", %{conn: conn, user: user} do
    Application.put_env(:shield, :otp_check, true)
    otp_secret = Otp.gen_secret
    otp_value = Otp.gen_totp(otp_secret)
    OneTimePassword.enable(user, otp_secret, otp_value)

    params = %{"email" => "foo@bar.com", "password" => "12345678",
      "otp_value" => otp_value}
    conn = post conn, user_path(conn, :login), user: params
    logged_in_user = json_response(conn, 201)["user"]
    token_value = conn |> fetch_session |> get_session("session_token")
    assert token_value
    assert @repo.get_by! @token_store, value: token_value, name: "session_token"
    assert logged_in_user
    assert logged_in_user["email"]
    refute logged_in_user["password"]
  end

  test "a POST request to /login with valid email & password when one time password enabled and wrong value", %{conn: conn, user: user} do
    Application.put_env(:shield, :otp_check, true)
    otp_secret = Otp.gen_secret
    otp_value = Otp.gen_totp(otp_secret)
    OneTimePassword.enable(user, otp_secret, otp_value)

    params = %{"email" => "foo@bar.com", "password" => "12345678",
      "otp_value" => "123456"}
    conn = post(conn, user_path(conn, :login), user: params)
    assert response(conn, 401)
  end

  test "a POST request to /login with valid email & password when confirmable but user not confirmed", %{conn: conn} do
    Application.put_env(:shield, :confirmable, true)

    params = %{"email" => "foo@bar.com", "password" => "12345678"}
    conn = post(conn, user_path(conn, :login), user: params)
    assert response(conn, 401)
  end

  test "a POST request to /login with valid email & wrong password", %{conn: conn} do
    params = %{"email" => "foo@bar.com", "password" => "87654321"}
    conn = post(conn, user_path(conn, :login), user: params)
    assert response(conn, 401)
  end

  test "a POST request to /login with non-existent email & password", %{conn: conn} do
    params = %{"email" => "nonexistent@bar.com", "password" => "12345678"}
    conn = post(conn, user_path(conn, :login), user: params)
    assert response(conn, 401)
  end

  test "a DELETE request to /logout with a valid session", %{conn: conn} do
    conn =
      conn
      |> sign_conn()
      |> delete(user_path(conn, :logout))
    assert response(conn, 204)
  end

  test "a DELETE request to /logout without a valid session", %{conn: conn} do
    conn = delete(conn, user_path(conn, :logout))
    assert response(conn, 403)
  end
end