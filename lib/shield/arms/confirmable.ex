defmodule Shield.Arm.Confirmable do
  @moduledoc """
  A behaviour for all Shield.Arm module for user email confirmation.
  """

  import Ecto.Query
  import Plug.Conn
  alias Shield.Notifier.Channel.Email, as: EmailNotifier

  @behaviour Shield.Arm
  @renderer Application.get_env(:authable, :renderer)
  @repo Application.get_env(:authable, :repo)
  @resource_owner Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)
  @front_end Application.get_env(:shield, :front_end)
  @front_end_base Map.get(@front_end, :base)

  def init(opts), do: Keyword.get opts, :enabled, false

  def call(conn, enabled), do: defend(conn, enabled)

  def defend(conn, false), do: conn
  def defend(conn, true), do: defend_conn(conn, conn.assigns[:current_user])

  def registration_hook(user), do: create_and_send_confirmation_token(user)

  def confirm(confirmation_token) do
    query = from t in @token_store,
              where: t.value == ^confirmation_token and
              t.name == "confirmation_token" and
              t.expires_at > ^:os.system_time(:seconds),
              preload: [:user],
              limit: 1

    case List.first(@repo.all(query)) do
      nil -> {:error, %{confirmation_token: "Token is invalid!"}}
      token ->
        @repo.delete!(token)
        update_confirm_status(token.user, true)
    end
  end

  defp defend_conn(conn, nil), do: conn
  defp defend_conn(conn, current_user) do
    case Map.get(current_user.settings || %{}, "confirmed", false) do
      true -> conn
      _ -> conn
           |> @renderer.render(:forbidden, %{errors: %{unconfirmed_user:
             "Confirmation required to access resource."}})
           |> halt
    end
  end

  defp update_confirm_status(user, status) do
    settings = user.settings || %{} |> Map.put(:confirmed, status)
    changeset = @resource_owner.settings_changeset(user, %{settings: settings})
    @repo.update(changeset)
  end

  defp create_and_send_confirmation_token(user) do
    changeset = @token_store.changeset(%@token_store{}, %{
      user_id: user.id,
      name: "confirmation_token",
      expires_at: :os.system_time(:seconds) + 3600
    })
    case @repo.insert(changeset) do
      {:ok, token} ->
        confirmation_url = String.replace(@front_end_base <>
          Map.get(@front_end, :confirmation_path),
          "{{confirmation_token}}", token.value)
        EmailNotifier.deliver([user.email], :confirmation,
          %{identity: user.email, confirmation_url: confirmation_url})
        {:ok, token}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
