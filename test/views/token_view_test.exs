defmodule Shield.TokenViewTest do
  use Shield.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  import Shield.Factory
  alias Shield.TokenView

  setup do
    user = insert(:user)
    client = insert(:client, user: user)
    token = insert(:access_token, user: user, details: %{client_id: client.id, scope: "read"})
    {:ok, token: token}
  end

  test "renders show.json", %{token: token} do
    assert render(TokenView, "show.json", %{token: token}) == %{
      token: %{details: token.details,
      expires_at: token.expires_at,
      name: "access_token",
      value: token.value}}
  end

  test "renders token.json", %{token: token} do
    assert render(TokenView, "token.json", %{token: token}) == %{
      details: token.details,
      expires_at: token.expires_at,
      name: "access_token",
      value: token.value}
  end
end
