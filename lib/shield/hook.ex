defmodule Shield.Hook do
  @moduledoc """
  This module helps to sync and async hooks into the lifecycle of
  public actions.
  """
  use Behaviour

  defmacro __using__(_) do
    quote do
      @behaviour Shield.Hook

      def before_app_authorize(conn, _), do: conn
      def after_app_authorize_failure(conn, errors, status), do: conn
      def after_app_authorize_success(conn, token), do: conn
      def before_app_delete(conn, _), do: conn
      def after_app_delete(conn), do: conn
      def before_client_create(conn, _), do: conn
      def after_client_create_success(conn, client), do: conn
      def after_client_create_failure(conn, changeset), do: conn
      def before_client_update(conn, _), do: conn
      def after_client_update_failure(conn, changeset), do: conn
      def after_client_update_success(conn, client), do: conn
      def before_client_delete(conn, _), do: conn
      def after_client_delete(conn), do: conn
      def before_token_create(conn, _), do: conn
      def after_token_create_failure(conn, errors, status), do: conn
      def after_token_create_success(conn, token), do: conn
      def before_user_register(conn, _), do: conn
      def after_user_register_failure(conn, changeset), do: conn
      def after_user_register_success(conn, user), do: conn
      def before_user_login(conn, _), do: conn
      def after_user_login_failure(conn, errors, http_status_code), do: conn
      def after_user_login_token_failure(conn, changeset), do: conn
      def after_user_login_token_success(conn, token), do: conn

      defoverridable [
        {:before_app_authorize, 2},
        {:after_app_authorize_failure, 3},
        {:after_app_authorize_success, 2},
        {:before_app_delete, 2},
        {:after_app_delete, 1},
        {:before_client_create, 2},
        {:after_client_create_failure, 2},
        {:after_client_create_success, 2},
        {:before_client_update, 2},
        {:after_client_update_failure, 2},
        {:after_client_update_success, 2},
        {:before_client_delete, 2},
        {:after_client_delete, 1},
        {:before_token_create, 2},
        {:after_token_create_failure, 3},
        {:after_token_create_success, 2},
        {:before_user_register, 2},
        {:after_user_register_failure, 2},
        {:after_user_register_success, 2},
        {:before_user_login, 2},
        {:after_user_login_failure, 3},
        {:after_user_login_token_failure, 2},
        {:after_user_login_token_success, 2}
      ]
    end
  end

  @type resource_owner_t :: Authable.Model.User.t
  @type token_store_t :: Authable.Model.Token.t
  @type client_t :: Authable.Model.Client.t

  @callback before_app_authorize(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_app_authorize_failure(conn :: Plug.Conn.t, errors :: Map,
    http_status_code :: atom) :: Plug.Conn.t

  @callback after_app_authorize_success(conn :: Plug.Conn.t,
    token :: token_store_t) :: Plug.Conn.t

  @callback before_app_delete(conn :: Plug.Conn.t, params :: any) :: Plug.Conn.t

  @callback after_app_delete(conn :: Plug.Conn.t) :: Plug.Conn.t

  @callback before_client_create(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_create_failure(conn :: Plug.Conn.t,
    params :: any) :: Plug.Conn.t

  @callback after_client_create_success(conn :: Plug.Conn.t,
    params :: any) :: Plug.Conn.t

  @callback before_client_update(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_update_failure(conn :: Plug.Conn.t, changeset :: any)
    :: Plug.Conn.t

  @callback after_client_update_success(conn :: Plug.Conn.t,
    client :: client_t) :: Plug.Conn.t

  @callback before_client_delete(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_delete(conn :: Plug.Conn.t) :: Plug.Conn.t

  @callback before_token_create(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_token_create_failure(conn :: Plug.Conn.t, errors :: Map,
    http_status_code :: atom) :: Plug.Conn.t

  @callback after_token_create_success(conn :: Plug.Conn.t,
    token :: token_store_t) :: Plug.Conn.t

  @callback before_user_register(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_register_failure(conn :: Plug.Conn.t, changeset :: any)
    :: Plug.Conn.t

  @callback after_user_register_success(conn :: Plug.Conn.t,
    user :: resource_owner_t) :: Plug.Conn.t

  @callback before_user_login(conn :: Plug.Conn.t, params :: any) :: Plug.Conn.t

  @callback after_user_login_failure(conn :: Plug.Conn.t, errors :: Map,
    http_status_code :: atom) :: Plug.Conn.t

  @callback after_user_login_token_failure(conn :: Plug.Conn.t,
    changeset :: any) :: Plug.Conn.t

  @callback after_user_login_token_success(conn :: Plug.Conn.t,
    token :: token_store_t) :: Plug.Conn.t

end

defmodule Shield.Hook.Default do
  @moduledoc """
  Default implementation of Shield.Hook.
  """
  use Shield.Hook
end
