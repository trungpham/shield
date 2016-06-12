defmodule Shield.SessionAuthTest do
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

  test "returns user model when authenticates with session using valid data", %{conn: conn} do
    user = insert(:user)
    token = insert(:session_token, value: "st1234567890", user_id: user.id)
    conn = conn |> sign_conn |> put_session(:session_token, token.value)
    assert user == Shield.SessionAuth.authenticate(conn)
  end
end
