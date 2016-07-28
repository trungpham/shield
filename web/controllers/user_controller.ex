defmodule Shield.UserController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Authable.Utils.Crypt, as: CryptUtil

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)
  @views Application.get_env(:shield, :views)
  @renderer Application.get_env(:authable, :renderer)

  plug :scrub_params, "user" when action in [:register, :login]
  plug :before_user_register when action in [:register]
  plug :before_user_login when action in [:login]
  plug Authable.Plug.Authenticate, [scopes: ~w(read write)] when action in [:me, :logout]
  plug Authable.Plug.UnauthorizedOnly when action in [:register, :login]

  def me(conn, _) do
    conn
    |> put_status(:ok)
    |> render(@views[:user], "show.json", user: conn.assigns[:current_user])
  end

  def register(conn, %{"user" => user_params}) do
    changeset = @user.registration_changeset(%@user{}, user_params)
    case @repo.insert(changeset) do
      {:ok, user} ->
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

  def login(conn, %{"user" => user_params}) do
    user = @repo.get_by(@user, email: user_params["email"])
    try_login(conn, user, user_params)
  end

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

  defp try_login(conn, nil, _user_params) do
    {http_status_code, errors} = {:unauthorized,
      %{invalid_identity: "Identity could not found."}}
    conn
    |> @hooks.after_user_login_failure(errors, http_status_code)
    |> @renderer.render(http_status_code, %{errors: errors})
  end
  defp try_login(conn, _user, false) do
    {http_status_code, errors} = {:unauthorized,
      %{invalid_identity: "Identity, password combination is wrong."}}
    conn
    |> @hooks.after_user_login_failure(errors, http_status_code)
    |> @renderer.render(http_status_code, %{errors: errors})
  end
  defp try_login(conn, user, true) do
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
  defp try_login(conn, user, user_params), do: try_login(conn, user,
    match_with_user_password(user_params["password"], user))

  defp match_with_user_password(password, user) do
    CryptUtil.match_password(password, Map.get(user, :password, ""))
  end
end