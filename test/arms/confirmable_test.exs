defmodule Shield.Arm.ConfirmableTest do
  use Shield.ConnCase
  import Shield.Factory
  alias Shield.Arm.Confirmable, as: ConfirmablePlug

  @opts ConfirmablePlug.init([enabled: true])

  setup do
    {:ok, conn: build_conn()}
  end

  test "defend with confirmed user", %{conn: conn} do
    user = insert(:user, settings: %{"confirmed" => true})
    conn = conn |> assign(:current_user, user) |> ConfirmablePlug.call(@opts)
    assert conn.state == :unset
    assert conn.status != 403
  end

  test "defend with unconfirmed user", %{conn: conn} do
    user = insert(:user, settings: %{"confirmed" => false})
    conn = conn |> assign(:current_user, user) |> ConfirmablePlug.call(@opts)
    assert conn.state == :set
    assert conn.status == 403
  end

  test "defend with unconfirmed user, when defend not enabled!", %{conn: conn} do
    user = insert(:user, settings: %{"confirmed" => false})
    conn = conn |> assign(:current_user, user) |> ConfirmablePlug.call(false)
    assert conn.state == :unset
    assert conn.status != 403
  end
end
