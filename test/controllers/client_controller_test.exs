defmodule Shield.ClientControllerTest do
  use Shield.ConnCase
  import Shield.Factory

  @repo Application.get_env(:authable, :repo)
  @client Application.get_env(:authable, :client)

  @valid_attrs %{redirect_uri: "https://example.com/oauth/callback", settings: %{language: "EN"}}
  @invalid_attrs %{name: "foo loo"}

  setup %{conn: conn} do
    user = insert(:user)
    client = insert(:client, user_id: user.id)
    insert(:app, user_id: user.id, client_id: client.id)
    access_token = insert(:access_token, user_id: user.id,
      details: %{client_id: client.id, scope: "session,read,write"})

    {:ok,
     conn: conn
     |> put_req_header("authorization", "Bearer #{access_token.value}")
     |> put_req_header("accept", "application/json"),
     client: client
    }
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, client_path(conn, :index)
    assert json_response(conn, 200)["clients"] |> Enum.count == 1
  end

  test "shows chosen resource", %{conn: conn, client: client} do
    conn = get conn, client_path(conn, :show, client)
    assert json_response(conn, 200)["client"] == %{"id" => client.id,
      "name" => client.name,
      "secret" => client.secret,
      "redirect_uri" => client.redirect_uri,
      "settings" => %{
        "name" => client.settings[:name],
        "icon" => client.settings[:icon]
      }}
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    conn = get conn, client_path(conn, :show, "11111111-1111-1111-1111-111111111111")
    assert response(conn, 404)
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, client_path(conn, :create), client: Map.put(@valid_attrs, :name, "testclient")
    assert json_response(conn, 201)["client"]["id"]
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, client_path(conn, :create), client: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn, client: client} do
    conn = put conn, client_path(conn, :update, client), client: @valid_attrs
    assert json_response(conn, 200)["client"]["settings"]["language"] == "EN"
    assert @repo.get(@client, client.id).settings["language"] == "EN"
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, client: client} do
    conn = put conn, client_path(conn, :update, client), client: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "does not update chosen resource and renders previous secret", %{conn: conn, client: client} do
    new_secret = "fooloo"
    conn = put conn, client_path(conn, :update, client), client: Map.put(@valid_attrs, :secret, new_secret)
    assert @repo.get(@client, client.id).secret != new_secret
    assert json_response(conn, 200)["client"]["secret"] != new_secret
  end

  test "deletes chosen resource", %{conn: conn, client: client} do
    conn = delete conn, client_path(conn, :delete, client)
    assert response(conn, 204)
    refute @repo.get(@client, client.id)
  end
end
