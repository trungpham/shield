defmodule Shield.UserController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Shield.Policy.Login, as: LoginPolicy
  alias Shield.Notifier.Channel.Email, as: EmailChannel
  alias Authable.Utils.Crypt, as: CryptUtil
  alias Shield.Query.Token, as: TokenQuery

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)
  @renderer Application.get_env(:authable, :renderer)
  @views Application.get_env(:shield, :views)
  @front_end Application.get_env(:shield, :front_end)

  plug :scrub_params, "user" when action in [:register, :login]
  plug :before_user_register when action in [:register]
  plug :before_user_login when action in [:login]
  plug Authable.Plug.Authenticate, [scopes: ~w(read)] when action in [:me]
  plug Authable.Plug.Authenticate, [scopes: ~w(read write)] when action in [:logout]
  plug Authable.Plug.Authenticate, [scopes: ~w(session read write)] when action in [:change_password]
  plug Authable.Plug.UnauthorizedOnly when action in [:register, :login, :confirm, :recover_password, :reset_password]
  plug Shield.Arm.Confirmable, [enabled: Application.get_env(:shield, :confirmable)] when action in [:me, :change_password]

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
        @renderer.render(conn, :forbidden, %{errors:
          %{confirmation_token: error}})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
      {:ok, _} ->
        @renderer.render(conn, :ok,
          %{messages: "Email confirmed successfully!"})
    end
  end

  # POST /users/recover-password
  def recover_password(conn, %{"user" => %{"email" => email}}) do
    recover_user_password(conn, @repo.get_by(@user, email: email))
  end

  # POST /users/reset-password
  def reset_password(conn, %{"user" => %{"password" => new_password, "reset_token" => reset_token}}) do
    token =
      reset_token
      |> TokenQuery.valid_reset_token()
      |> @repo.get_by([])

    case token do
      nil ->
        @renderer.render(conn, :forbidden, %{errors:
          %{reset_token: "Invalid token."}})
      _ ->
        @repo.delete!(token)
        change_password(conn, true, token.user, new_password)
    end
  end

  # POST /users/change-password
  def change_password(conn, %{"user" => %{"password" => new_password, "old_password" => old_password}}) do
    is_password_matched = CryptUtil.match_password(old_password,
      Map.get(conn.assigns[:current_user], :password, ""))
    change_password(conn, is_password_matched,
      conn.assigns[:current_user], new_password)
  end

  # POST /users/register
  def register(conn, %{"user" => user_params}) do
    changeset = @user.registration_changeset(%@user{}, user_params)
    case @repo.insert(changeset) do
      {:ok, user} ->
        confirmable = Application.get_env(:shield, :confirmable)
        if confirmable, do: Shield.Arm.Confirmable.registration_hook(user)
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
  def login(conn, %{"user" => %{"email" => email, "password" => password} = params}) when is_binary(password) and is_binary(email) do
    case LoginPolicy.check(params) do
      {:error, {http_status_code, errors}} ->
        conn
        |> @hooks.after_user_login_failure(errors, http_status_code)
        |> @renderer.render(http_status_code, %{errors: errors})
      {:ok, %{"user" => user}} ->
        insert_session_token(conn, user)
    end
  end
  def login(conn, _) do
    @renderer.render(conn, :unprocessable_entity, %{errors:
      %{details: "Invalid email or password format!"}})
  end

  # DELETE /users/logout
  def logout(conn, _) do
    token_value = get_session(fetch_session(conn), :session_token)
    token = @repo.get_by!(@token_store, name: "session_token",
      value: token_value)
    @repo.delete!(token)

    conn
    |> fetch_session()
    |> configure_session(drop: true)
    |> send_resp(:no_content, "")
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
        EmailChannel.deliver([user.email], :recover_password,
          %{identity: user.email, recover_password_url: recover_password_url})

        @renderer.render(conn, :created, %{messages: "Email sent!"})
      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:error], "422.json")
    end
  end

  defp change_password(conn, false, _, _) do
    @renderer.render(conn, :forbidden, %{errors:
      %{old_password: "Wrong old password."}})
  end
  defp change_password(conn, true, user, password) do
    changeset = @user.password_changeset(user, %{password: password})
    case @repo.update(changeset) do
      {:ok, _} ->
        @renderer.render(conn, :ok, %{messages: "Password updated!"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
    end
  end

  defp insert_session_token(conn, user) do
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
end
