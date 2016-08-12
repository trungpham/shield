defmodule Shield.ClientView do
  use Shield.Web, :view

  def render("index.json", %{clients: clients}) do
    %{clients: render_many(clients, __MODULE__, "client.json")}
  end

  def render("show.json", %{client: client, is_owner: true}) do
    %{client: render_one(client, __MODULE__, "client.json")}
  end

  def render("show.json", %{client: client, is_owner: false}) do
    %{client: render_one(client, __MODULE__, "app_client.json")}
  end

  def render("show.json", %{client: client, is_owner: nil}) do
    %{client: render_one(client, __MODULE__, "app_client.json")}
  end

  def render("show.json", %{client: client}) do
    %{client: render_one(client, __MODULE__, "client.json")}
  end

  def render("client.json", %{client: client}) do
    json = %{id: client.id,
             name: client.name,
             secret: client.secret,
             redirect_uri: client.redirect_uri}
    if is_nil(client.settings),
      do: json,
      else: Map.put(json, :settings, client.settings)
  end

  def render("app_client.json", %{client: client}) do
    json = %{id: client.id,
             name: client.name,
             redirect_uri: client.redirect_uri}
    if is_nil(client.settings),
      do: json,
      else: Map.put(json, :settings, client.settings)
  end
end
