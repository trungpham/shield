defmodule Shield.Hook do
  @moduledoc """
  This module helps to sync and async hooks into the lifecycle of
  public actions.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Shield.Hook

      def before_app_authorize(conn, _params),
        do: conn

      def before_app_delete(conn, _params),
        do: conn

      def after_app_authorize_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_app_authorize_success(conn, {_params, _res}),
        do: conn

      def after_app_delete(conn, _params),
        do: conn

      def before_client_create(conn, _params),
        do: conn

      def before_client_update(conn, _params),
        do: conn

      def before_client_delete(conn, _params),
        do: conn

      def after_client_create_success(conn, {_params, _res}),
        do: conn

      def after_client_create_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_client_update_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_client_update_success(conn, _client),
        do: conn

      def after_client_delete(conn, _params),
        do: conn

      def before_token_create(conn, _params),
        do: conn

      def after_token_create_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_token_create_success(conn, {_params, _res}),
        do: conn

      def before_user_register(conn, _params),
        do: conn

      def before_user_login(conn, _params),
        do: conn

      def after_user_change_password_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_change_password_success(conn, {_params, _res}),
        do: conn

      def after_user_confirm_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_confirm_success(conn, {_params, _res}),
        do: conn

      def after_user_login_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_login_success(conn, {_params, _res}),
        do: conn

      def after_user_recover_password_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_recover_password_success(conn, {_params, _res}),
        do: conn

      def after_user_register_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_register_success(conn, {_params, _res}),
        do: conn

      def after_user_reset_password_failure(conn, {_params, {_http_status_code, _res}}),
        do: conn

      def after_user_reset_password_success(conn, {_params, _res}),
        do: conn

      defoverridable [
        {:before_app_authorize, 2},
        {:after_app_authorize_failure, 2},
        {:after_app_authorize_success, 2},
        {:before_app_delete, 2},
        {:after_app_delete, 2},
        {:before_client_create, 2},
        {:after_client_create_failure, 2},
        {:after_client_create_success, 2},
        {:before_client_delete, 2},
        {:after_client_delete, 2},
        {:before_client_update, 2},
        {:after_client_update_failure, 2},
        {:after_client_update_success, 2},
        {:before_token_create, 2},
        {:after_token_create_failure, 2},
        {:after_token_create_success, 2},

        {:before_user_register, 2},
        {:before_user_login, 2},
        {:after_user_change_password_failure, 2},
        {:after_user_change_password_success, 2},
        {:after_user_confirm_failure, 2},
        {:after_user_confirm_success, 2},
        {:after_user_login_failure, 2},
        {:after_user_login_success, 2},
        {:after_user_recover_password_failure, 2},
        {:after_user_recover_password_success, 2},
        {:after_user_register_failure, 2},
        {:after_user_register_success, 2},
        {:after_user_reset_password_failure, 2},
        {:after_user_reset_password_success, 2}
      ]
    end
  end

  @callback before_app_authorize(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_app_authorize_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_app_authorize_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_app_delete(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_app_delete(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_client_create(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_create_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_create_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_client_delete(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_delete(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_client_update(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_update_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_client_update_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_token_create(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_token_create_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_token_create_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_user_register(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback before_user_login(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_change_password_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_change_password_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_confirm_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_confirm_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_login_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_login_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_recover_password_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_recover_password_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_register_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_register_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_reset_password_failure(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t

  @callback after_user_reset_password_success(conn :: Plug.Conn.t, params :: any) ::
    Plug.Conn.t
end

defmodule Shield.Hook.Default do
  @moduledoc """
  Default implementation of Shield.Hook.
  """
  use Shield.Hook
end
