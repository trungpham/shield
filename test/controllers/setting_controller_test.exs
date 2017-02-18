defmodule Shield.SettingControllerTest do
  use Shield.ConnCase
  use ExUnit.Case, async: false
  import ExUnit.Assertions
  import Shield.Factory
  alias Shield.Arm.OneTimePassword
  alias Comeonin.Otp

  @repo Application.get_env(:authable, :repo)
  @app Application.get_env(:authable, :app)

  setup %{conn: conn} do
    user = insert(:user, settings: %{"otp_enabled" => false})
    otp_secret = Otp.gen_secret
    otp_value = Otp.gen_totp(otp_secret)

    client = insert(:client, user_id: user.id)
    insert(:app, user_id: user.id, client_id: client.id)
    access_token = insert(:access_token, user_id: user.id,
      details: %{client_id: client.id, scope: "session,read,write"})

    {:ok,
     conn: conn
           |> put_req_header("authorization", "Bearer #{access_token.value}")
           |> put_req_header("accept", "application/json"),
     user: user,
     otp_secret: otp_secret,
     otp_value: otp_value
    }
  end

  test "lists all settings on index for current user", %{conn: conn} do
    conn = get conn, setting_path(conn, :index)
    assert json_response(conn, 200)["settings"] |> Enum.count == 1
  end

  test "enable otp when otp enabled by config", %{conn: conn, user: user, otp_secret: otp_secret, otp_value: otp_value} do
    Application.put_env(:shield, :one_time_password_enabled, true, persistent: true)

    data = %{"setting" => %{"one_time_password" => %{"action" => "enable",
      "otp_secret" => otp_secret, "otp_value" => otp_value}}}
    conn = put conn, setting_path(conn, :update, "one_time_password", data)
    assert response(conn, 200)
  end

  test "enable otp when otp is disabled by config", %{conn: conn, user: user, otp_secret: otp_secret, otp_value: otp_value} do
    Application.put_env(:shield, :one_time_password_enabled, false, persistent: true)
    data = %{"setting" => %{"one_time_password" => %{"action" => "enable",
      "otp_secret" => otp_secret, "otp_value" => otp_value}}}
    conn = put conn, setting_path(conn, :update, "one_time_password", data)
    assert response(conn, 422)
  end

  test "disable otp when otp enabled by config", %{conn: conn, user: user, otp_secret: otp_secret, otp_value: otp_value} do
    Application.put_env(:shield, :one_time_password_enabled, true, persistent: true)
    OneTimePassword.enable(user, otp_secret, otp_value)

    data = %{"setting" => %{"one_time_password" => %{"action" => "disable",
      "otp_value" => otp_value}}}
    conn = put conn, setting_path(conn, :update, "one_time_password", data)
    assert response(conn, 200)
  end

  test "disable otp when otp disabled by config", %{conn: conn, user: user, otp_secret: otp_secret, otp_value: otp_value} do
    Application.put_env(:shield, :one_time_password_enabled, false, persistent: true)
    OneTimePassword.enable(user, otp_secret, otp_value)

    data = %{"setting" => %{"one_time_password" => %{"action" => "disable",
      "otp_value" => otp_value}}}
    conn = put conn, setting_path(conn, :update, "one_time_password", data)
    assert response(conn, 422)
  end

  test "response with unprocessable entity error code", %{conn: conn} do
    conn = put conn, setting_path(conn, :update, "one_time_password", %{})
    assert response(conn, 422)
  end
end
