defmodule Shield.ErrorView do
  use Shield.Web, :view

  def render("400.json", _anything) do
    %{errors: %{details: "Bad request!"}}
  end

  def render("401.json", _anything) do
    %{errors: %{details: "Failed to authenticate!"}}
  end

  def render("404.json", _anything) do
    %{errors: %{details: "Not found!"}}
  end

  def render("422.json", _anything) do
    %{errors: %{details: "Unprocessable entity!"}}
  end

  def render("500.json", _anything) do
    %{errors: %{details: "Internal server error."}}
  end

  def render("already_logged_in.json", _anything) do
    %{errors: %{details: "Already logged in!"}}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
