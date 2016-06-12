defmodule Shield.AppViewTest do
  use Shield.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  import Shield.Factory
  alias Shield.AppView

  setup do
    user = insert(:user)
    client = insert(:client, user: user)
    app = insert(:app, user: user, client: client)
    {:ok, user: user, client: client, app: app}
  end

  test "renders index.json", %{client: client, app: app} do
    assert render(AppView, "index.json", %{apps: [app]}) ==
      %{apps: [%{client: %{
          id: client.id,
          name: client.name,
          redirect_uri: client.redirect_uri,
          settings: client.settings
        },
        id: app.id,
        scope: app.scope}]
      }
  end

  test "renders show.json", %{client: client, app: app} do
    assert render(AppView, "show.json", %{app: app}) ==
      %{app: %{client: %{
          id: client.id,
          name: client.name,
          redirect_uri: client.redirect_uri,
          settings: client.settings
        },
        id: app.id,
        scope: app.scope}}
  end

  test "renders app.json", %{client: client, app: app} do
    assert render(AppView, "app.json", %{app: app}) ==
      %{client: %{
          id: client.id,
          name: client.name,
          redirect_uri: client.redirect_uri,
          settings: client.settings
        },
        id: app.id,
        scope: app.scope}
  end
end
