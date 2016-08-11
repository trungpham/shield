defmodule Shield.UserController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Shield.Notifier.Channel.Email, as: EmailNotifier
  alias Authable.Utils.Crypt, as: CryptUtil

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)
  @renderer Application.get_env(:authable, :renderer)
  @views Application.get_env(:shield, :views)
  @front_end Application.get_env(:shield, :front_end)
  @front_end_base Map.get(@front_end, :base)
  @confirmable Application.get_env(:shield, :confirmable)

  plug :scrub_params, "user" when action in [:register, :login]
  plug :before_user_register when action in [:register]
  plug :before_user_login when action in [:login]
  plug Authable.Plug.Authenticate, [scopes: ~w(read write)] when action in [:me, :logout, :change_password]
  plug Authable.Plug.UnauthorizedOnly when action in [:register, :login, :confirm, :recover_password, :reset_password]
  plug Shield.Arm.Confirmable, [enabled: @confirmable] when action in [:me, :change_password]

  # GET /users/me
  def me(conn, _) do
    conn
    |> put_status(:ok)
    |> render(@views[:user], "show.json", user: conn.assigns[:current_user])
  end

  # GET /users/confirm
  def confirm(conn, %{"confirmation_token" => token_value}) do
    case Shield.Arm.Confirmable.confirm(token_value) do
      {:error, %{confirmation_token: error}} ->
        conn
        |> @renderer.render(:forbidden, %{errors: %{confirmation_token: error}})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
      {:ok, _} ->
        conn
        |> @renderer.render(:ok, %{messages: "Email confirmed successfully!"})
    end
  end

  # POST /users/recover-password
  def recover_password(conn, %{"email" => email}) do
    recover_user_password(conn, @repo.get_by(@user, email: email))
  end

  # POST /users/reset-password
  def reset_password(conn, %{"password" => new_password, "reset_token" => reset_token}) do
    query = from t in @token_store,
          where: t.value == ^reset_token and
          t.name == "reset_token" and
          t.expires_at > ^:os.system_time(:seconds),
          preload: [:user],
          limit: 1

    reset_password(conn, List.first(@repo.all(query)), new_password)
  end

  # POST /users/change-password
  def change_password(conn, %{"password" => new_password, "old_password" => old_password}) do
    change_password(conn,
      match_with_user_password(old_password, conn.assigns[:current_user]),
      conn.assigns[:current_user], new_password)
  end

  # POST /users/register
  def register(conn, %{"user" => user_params}) do
    changeset = @user.registration_changeset(%@user{}, user_params)
    case @repo.insert(changeset) do
      {:ok, user} ->
        Shield.Arm.Confirmable.registration_hook(user)
        conn
        |> @hooks.after_user_register_success(user)
        |> put_status(:created)
        |> render(@views[:user], "show.json", user: user)
      {:error, changeset} ->
        conn
        |> @hooks.after_user_register_failure(changeset)
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
    end
  end

  # POST /users/login
  def login(conn, %{"user" => %{"email" => email, "password" => password}}) when is_binary(password) and is_binary(email) do
    user = @repo.get_by(@user, email: email)
    try_login(conn, user, password)
  end
  def login(conn, _) do
    conn |> @renderer.render(:unprocessable_entity, %{errors:
      %{details: "Invalid email or password format!"}})
  end

  # DELETE /users/logout
  def logout(conn, _) do
    token_value = conn |> fetch_session |> get_session(:session_token)
    token = @repo.get_by!(@token_store, name: "session_token",
              value: token_value)
    @repo.delete!(token)

    conn
    |> fetch_session
    |> configure_session(drop: true)
    |> send_resp(:no_content, "")
  end

  defp try_login(conn, nil, _) do
    {http_status_code, errors} = {:unauthorized,
      %{email: "Email could not found."}}
    conn
    |> @hooks.after_user_login_failure(errors, http_status_code)
    |> @renderer.render(http_status_code, %{errors: errors})
  end
  defp try_login(conn, _, false) do
    {http_status_code, errors} = {:unauthorized, %{password: "Wrong password!"}}
    conn
    |> @hooks.after_user_login_failure(errors, http_status_code)
    |> @renderer.render(http_status_code, %{errors: errors})
  end
  defp try_login(conn, user, true) do
    try_login(conn, user, true,
      @confirmable && Map.get(user.settings || %{}, "confirmed", false))
  end
  defp try_login(conn, user, password), do:
    try_login(conn, user, match_with_user_password(password, user))
  defp try_login(conn, user, true, false) do
    conn
    |> @renderer.render(:unauthorized, %{errors: %{email:
         "Email confirmation required to login."}})
  end
  defp try_login(conn, user, true, true) do
    changeset = @token_store.session_token_changeset(%@token_store{},
                  %{user_id: user.id, details: %{"scope" => "session"}})
    case @repo.insert(changeset) do
      {:ok, token} ->
        conn
        |> @hooks.after_user_login_token_success(token)
        |> assign(:current_user, user)
        |> fetch_session
        |> put_session(:session_token, token.value)
        |> configure_session(renew: true)
        |> put_status(:created)
        |> render(@views[:user], "show.json", user: user)
      {:error, changeset} ->
        conn
        |> @hooks.after_user_login_token_failure(changeset)
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
    end
  end

  defp recover_user_password(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render(@views[:error], "404.json")
  end
  defp recover_user_password(conn, user) do
    changeset = @token_store.changeset(%@token_store{}, %{
      user_id: user.id,
      name: "reset_token",
      expires_at: :os.system_time(:seconds) + 3600
    })
    case @repo.insert(changeset) do
      {:ok, token} ->
        recover_password_url = String.replace((Map.get(@front_end, :base) <>
          Map.get(@front_end, :reset_password_path)), "{{reset_token}}",
          token.value)
        EmailNotifier.deliver(
          [user.email],
          :recover_password,
          %{identity: user.email,
            recover_password_url: recover_password_url}
        )
        conn
        |> @renderer.render(:created, %{messages: "Email sent!"})
      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:error], "422.json")
    end
  end

  defp reset_password(conn, nil, _) do
    conn |> @renderer.render(:forbidden, %{errors: %{reset_token:
      "Invalid token."}})
  end
  defp reset_password(conn, token, password), do: change_password(conn, true,
    token.user, password)

  defp change_password(conn, false, _, _) do
    conn |> @renderer.render(:forbidden, %{errors: %{old_password:
      "Wrong old password."}})
  end
  defp change_password(conn, true, user, password) do
    changeset = @user.password_changeset(user, %{password: password})
    case @repo.update(changeset) do
      {:ok, _} ->
        conn
        |> @renderer.render(:ok, %{messages: "Password updated!"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
    end
  end

  defp match_with_user_password(password, user) do
    CryptUtil.match_password(password, Map.get(user, :password, ""))
  end
end
