defmodule Shield.Plug do
  @moduledoc """
  Shield plug implementation to check authentications and to set resouce owner.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [render: 3]
  alias Shield.SessionAuth
  alias Shield.QueryParamsAuth
  alias Shield.HeaderAuth

  @views Application.get_env(:shield, :views)

  @doc """
  Plug function to authenticate client for resouce owner and assigns resource
  owner into conn.assigns[:current_user] key.
  If it fails, then it halts connection and returns unauthorized(HTTP Status
  Code 401) header with error json.

  ## Examples

      defmodule SomeModule.AppController do
        use SomeModule.Web, :controller
        use Shield.Authorization

        plug :authenticate!

        def index(conn, _params) do
          # access to current user on successful authentication
          current_user = conn.assigns[:current_user]
          ...
        end
      end

      defmodule SomeModule.AppController do
        use SomeModule.Web, :controller
        use Shield.Authorization

        plug :authenticate! when action in [:create]

        def index(conn, _params) do
          # anybody can call this action
          ...
        end

        def create(conn, _params) do
          # only logged in users can access this action
          current_user = conn.assigns[:current_user]
          ...
        end
      end
  """
  def authenticate!(conn, _) do
    current_user = authenticate(conn)
    if is_nil(current_user) do
      conn
      |> put_status(:unauthorized)
      |> render(@views[:error], "401.json")
      |> halt
    else
      assign(conn, :current_user, current_user)
    end
  end

  @doc """
  Plug function to refute authencated users to access resources.

  ## Examples

      defmodule SomeModule.AppController do
        use SomeModule.Web, :controller
        use Shield.Authorization

        plug :already_logged_in? when action in [:register]

        def register(conn, _params) do
          # only not logged in user can access this action
        end
      end
  """
  def already_logged_in?(conn, _) do
    current_user = authenticate(conn)
    if is_nil(current_user) do
      assign(conn, :current_user, current_user)
    else
      conn
      |> put_status(:unprocessable_entity)
      |> render(@views[:error], "already_logged_in.json")
      |> halt
    end
  end

  @doc """
  Authenticate user by using configured authorization methods.

  ## Examples

      current_user = Shield.Plug.authenticate(conn)
      if is_nil(current_user) do
        IO.puts "not authencated!"
      else
        IO.puts current_user.email
      end
  """
  def authenticate(conn) do
    SessionAuth.authenticate(conn) || QueryParamsAuth.authenticate(conn) ||
      HeaderAuth.authenticate(conn)
  end
end
