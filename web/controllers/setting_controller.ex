defmodule Shield.SettingController do
  use Shield.Web, :controller

  @renderer Application.get_env(:authable, :renderer)

  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:update]
  plug Authable.Plug.Authenticate, [scopes: ~w(read)] when action in [:index]

  # GET /settings
  def index(conn, _) do
    user = conn.assigns[:current_user]
    @renderer.render(conn, :ok, %{settings: user.settings})
  end

  # PUT /settings/one_time_password
  def update(conn, %{"setting" => %{"one_time_password" => %{"action" => "enable", "otp_secret" => otp_secret, "otp_value" => otp_value}}}) do
    if Application.get_env(:shield, :one_time_password_enabled) do
      user = conn.assigns[:current_user]
      case Shield.Arm.OneTimePassword.enable(user, otp_secret, otp_value) do
        {:error, errors} ->
          @renderer.render(conn, :unprocessable_entity, %{errors: errors})
        {:ok, _} ->
          @renderer.render(conn, :ok, %{messages: "One time password enabled!"})
      end
    else
      @renderer.render(conn, :unprocessable_entity, %{errors:
        %{details: "OTP is not enabled by configuration!"}})
    end
  end
  def update(conn, %{"setting" => %{"one_time_password" => %{"action" => "disable", "otp_value" => otp_value}}}) do
    if Application.get_env(:shield, :one_time_password_enabled) do
      user = conn.assigns[:current_user]
      case Shield.Arm.OneTimePassword.disable(user, otp_value) do
        {:error, errors} ->
          @renderer.render(conn, :unprocessable_entity, %{errors: errors})
        {:ok, _} ->
          @renderer.render(conn, :ok, %{messages: "One time password disabled!"})
      end
    else
      @renderer.render(conn, :unprocessable_entity, %{errors:
        %{details: "OTP is not enabled by configuration!"}})
    end
  end
  def update(conn, _) do
    @renderer.render(conn, :unprocessable_entity, %{errors:
      %{details: "Unknown setting format!"}})
  end
end
