defmodule Shield.ClientViewTest do
  use Shield.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  import Shield.Factory
  alias Shield.ClientView

  setup do
    user = insert(:user)
    client = insert(:client, user: user)
    {:ok, user: user, client: client}
  end

  test "renders index.json", %{client: client} do
    assert render(ClientView, "index.json", %{clients: [client]}) ==
      %{clients: [%{
        id: client.id,
        name: client.name,
        redirect_uri: client.redirect_uri,
        secret: client.secret,
        settings: client.settings
      }]}
  end

  test "renders show.json", %{client: client} do
    assert render(ClientView, "show.json", %{client: client}) ==
      %{client: %{
        id: client.id,
        name: client.name,
        redirect_uri: client.redirect_uri,
        secret: client.secret,
        settings: client.settings
      }}
  end

  test "renders client.json", %{client: client} do
    assert render(ClientView, "client.json", %{client: client}) ==
      %{
        id: client.id,
        name: client.name,
        redirect_uri: client.redirect_uri,
        secret: client.secret,
        settings: client.settings
      }
  end

  test "renders app_client.json", %{client: client} do
    assert render(ClientView, "app_client.json", %{client: client}) ==
      %{
        id: client.id,
        name: client.name,
        redirect_uri: client.redirect_uri,
        settings: client.settings
      }
  end
end
