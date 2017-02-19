defmodule Shield.AppControllerTest do
  use Shield.ConnCase
  import Shield.Factory

  @repo Application.get_env(:authable, :repo)
  @app Application.get_env(:authable, :app)

  setup %{conn: conn} do
    user1 = insert(:user)
    user2 = insert(:user)
    user3 = insert(:user)

    client = insert(:client, user_id: user1.id)

    app1 = insert(:app, user_id: user2.id, client_id: client.id)
    app2 = insert(:app, user_id: user3.id, client_id: client.id)

    access_token = insert(:access_token, user_id: user2.id,
      details: %{client_id: client.id, scope: "session,read,write"})

    {:ok,
      conn: conn
            |> put_req_header("authorization", "Bearer #{access_token.value}")
            |> put_req_header("accept", "application/json"),
      app: app1,
      app2: app2,
      user: user1,
      client: client}
  end

  test "lists all entries on index for current user", %{conn: conn} do
    conn = get(conn, app_path(conn, :index))
    assert json_response(conn, 200)["apps"] |> Enum.count == 1
  end

  test "shows chosen resource that belongs to current user", %{conn: conn, app: app} do
    conn = get(conn, app_path(conn, :show, app))
    assert json_response(conn, 200)["app"]
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    conn = get(conn, client_path(conn, :show, "11111111-1111-1111-1111-111111111111"))
    assert response(conn, 404)
  end

  test "does not show resource and instead throw error when id not belongs to current user", %{conn: conn, app2: app2} do
    conn = get(conn, client_path(conn, :show, app2.id))
    assert response(conn, 404)
  end

  test "authorize app for current user", %{conn: conn, client: client} do
    params = %{"app" => %{"client_id" => client.id,
      "redirect_uri" => client.redirect_uri, "scope" => "read,write,session"}}
    conn = post(conn, app_path(conn, :authorize, params))
    assert json_response(conn, 201)["token"]
  end

  test "does not authorize app for current user when client not found", %{conn: conn, client: client} do
    params = %{"app" => %{"client_id" => "11111111-1111-1111-1111-111111111111",
      "redirect_uri" => client.redirect_uri, "scope" => "read"}}
    conn = post(conn, app_path(conn, :authorize, params))
    assert response(conn, 422)
  end

  test "deletes chosen resource belongs to current user", %{conn: conn, app: app} do
    conn = delete(conn, app_path(conn, :delete, app))
    assert response(conn, 204)
    refute @repo.get(@app, app.id)
  end

  test "does not delete chosen resource that not belongs to current user", %{conn: conn, app2: app2} do
    assert_error_sent 404, fn ->
      delete(conn, app_path(conn, :delete, app2))
    end
  end
end
