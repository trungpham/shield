defmodule Shield.TokenView do
  use Shield.Web, :view

  def render("show.json", %{token: token}) do
    %{token: render_one(token, __MODULE__, "token.json")}
  end

  def render("token.json", %{token: token}) do
    json = %{name: token.name,
             value: token.value,
             expires_at: token.expires_at}
    if is_nil(token.details), do: json,
                              else: Map.put(json, :details, token.details)
  end
end
