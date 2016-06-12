defmodule Shield.UserController do
  use Shield.Web, :controller
  use Shield.Authorization
  alias Authable.Utils.Crypt, as: CryptUtil

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)

  @views Application.get_env(:shield, :views)

  plug :scrub_params, "user" when action in [:register, :login]
  plug :authenticate! when action in [:me, :logout]
  plug :already_logged_in? when action in [:register, :login]

  def me(conn, _) do
    conn
    |> put_status(:created)
    |> render(@views[:user], "show.json", user: conn.assigns[:current_user])
  end

  def register(conn, %{"user" => user_params}) do
    changeset = @user.registration_changeset(%@user{}, user_params)
    case @repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(@views[:user], "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:changeset], "error.json", changeset: changeset)
    end
  end

  def login(conn, %{"user" => user_params}) do
    user = @repo.get_by(@user, email: user_params["email"])
    if user && match_with_user_password(user_params["password"], user) do
      changeset = @token_store.session_token_changeset(%@token_store{},
                                                       %{user_id: user.id})
      case @repo.insert(changeset) do
        {:ok, token} ->
          conn
          |> assign(:current_user, user)
          |> fetch_session
          |> put_session(:session_token, token.value)
          |> configure_session(renew: true)
          |> put_status(:created)
          |> render(@views[:user], "show.json", user: user)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(@views[:changeset], "error.json", changeset: changeset)
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(@views[:error], "401.json")
      |> halt
    end
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

  defp match_with_user_password(password, user) do
    CryptUtil.match_password(password, Map.get(user, :password, ""))
  end
end