defmodule Shield.TokenController do
  use Shield.Web, :controller
  use Shield.HookImporter
  alias Shield.Policy.Token.Authorize, as: AuthorizePolicy
  alias Shield.Store.Token, as: TokenStore

  @renderer Application.get_env(:authable, :renderer)
  @views Application.get_env(:shield, :views)
  @hooks Application.get_env(:shield, :hooks)

  plug :before_token_create when action in [:create]

  # GET /tokens/:id
  def show(conn, %{"id" => _, "client_id" => _, "client_secret" => _} = params) do
    case TokenStore.client_token(params) do
      {:ok, %{"token" => token}} ->
        conn
        |> put_status(:ok)
        |> render(@views[:token], "show.json", token: token)
      {:error, {http_status_code, errors}} ->
        @renderer.render(conn, http_status_code, %{errors: errors})
    end
  end

  # POST /tokens
  def create(conn, %{"token" => token_params}) do
    case AuthorizePolicy.process(token_params) do
      {:ok, token} ->
        conn
        |> @hooks.after_token_create_success({token_params, token})
        |> put_status(:created)
        |> render(@views[:token], "show.json", token: token)
      {:error, {http_status_code, errors} = res} ->
        conn
        |> @hooks.after_token_create_failure({token_params, res})
        |> @renderer.render(http_status_code, %{errors: errors})
    end
  end
end
