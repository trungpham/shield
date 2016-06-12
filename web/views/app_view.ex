defmodule Shield.AppView do
  use Shield.Web, :view
  alias Shield.ClientView

  def render("index.json", %{apps: apps}) do
    %{apps: render_many(apps, __MODULE__, "app.json")}
  end

  def render("show.json", %{app: app}) do
    %{app: render_one(app, __MODULE__, "app.json")}
  end

  def render("app.json", %{app: app}) do
    %{id: app.id,
      scope: app.scope,
      client: ClientView.render("app_client.json", %{client: app.client})}
  end
end
