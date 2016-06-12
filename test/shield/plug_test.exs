defmodule Shield.PlugTest do
  use Shield.ConnCase
  import Shield.Factory

  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt",
    log: false
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))
  @encrypted_opts Plug.Session.init(@default_opts)

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  defp sign_conn(conn) do
    put_in(conn.secret_key_base, @secret)
    |> Plug.Session.call(@signing_opts)
    |> fetch_session
  end

  test "test authenticate! with valid credentials", %{conn: conn} do
    user = insert(:user)
    token = insert(:session_token, user_id: user.id)
    conn = conn |> sign_conn |> put_session(:session_token, token.value)
    conn = Shield.Plug.authenticate!(conn, %{})

    assert user == Shield.Plug.authenticate(conn)
  end

  test "test authenticate! with no credentials", %{conn: conn} do
    user = insert(:user)
    insert(:session_token, user_id: user.id)
    conn = conn |> sign_conn
    conn = Shield.Plug.authenticate!(conn, %{})

    assert response(conn, 401)
    assert is_nil(conn.assigns[:current_user])
  end

  test "test already_logged_in? with valid credentials", %{conn: conn} do
    user = insert(:user)
    token = insert(:session_token, user_id: user.id)
    conn = conn |> sign_conn |> put_session(:session_token, token.value)
    conn = Shield.Plug.already_logged_in?(conn, %{})

    assert response(conn, 422)
    assert user == Shield.Plug.authenticate(conn)
  end

  test "test already_logged_in? with no credentials", %{conn: conn} do
    user = insert(:user)
    insert(:session_token, user_id: user.id)
    conn = conn |> sign_conn
    conn = Shield.Plug.already_logged_in?(conn, %{})

    assert is_nil(conn.assigns[:current_user])
  end
end