defmodule Shield.TokenController do
  use Shield.Web, :controller
  use Shield.Authorization
  alias Authable.OAuth2, as: OAuth2

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @client Application.get_env(:authable, :client)
  @token_store Application.get_env(:authable, :token_store)

  @views Application.get_env(:shield, :views)

  def show(conn, %{"id" => token_value, "client_id" => client_id, "client_secret" => secret}) do
    token = @repo.get_by(@token_store, value: token_value)
    if is_nil(token) do
      conn
      |> put_status(:not_found)
      |> render(@views[:error], "404.json")
      |> halt
    else
      client = @repo.get_by(@client, id: client_id, secret: secret)
      if is_nil(client) ||
        Map.get(token.details, "client_id", "") != client_id do
        conn
          |> put_status(:not_found)
          |> render(@views[:error], "404.json")
      else
        conn
          |> put_status(:ok)
          |> render(@views[:token], "show.json", token: token)
      end
    end
  end

  def create(conn, params) do
    token = OAuth2.authorize(params)
    if is_nil(token) do
      conn
        |> put_status(:unprocessable_entity)
        |> render(@views[:error], "422.json")
    else
      conn
        |> put_status(:created)
        |> render(@views[:token], "show.json", token: token)
    end
  end
end
