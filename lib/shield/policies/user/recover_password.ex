defmodule Shield.Policy.User.RecoverPassword do
  @moduledoc """
  User.RecoverPassword policy
  """

  alias Shield.Notifier.Channel.Email, as: EmailChannel

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)
  @token_store Application.get_env(:authable, :token_store)
  @front_end Application.get_env(:shield, :front_end)
  @reset_token_timeout 3600

  @doc """
  Runs password recovery process for given params
  - Validates email existence
  - Creates reset token
  - Send token to user's email
  """
  def process(params) do
    params
    |> validate_email_exists()
    |> create_reset_token()
    |> deliver_email()
  end

  defp validate_email_exists(%{"email" => email} = params) do
    case @repo.get_by(@user, email: email) do
      nil -> {:error, {:not_found, %{email: ["Email could not found."]}}}
      user -> {:ok, Map.put(params, "user", user)}
    end
  end

  defp create_reset_token({:ok, %{"user" => user} = params}) do
    changeset = @token_store.changeset(%@token_store{}, %{
      user_id: user.id,
      name: "reset_token",
      expires_at: :os.system_time(:seconds) + @reset_token_timeout
    })

    case @repo.insert(changeset) do
      {:ok, token} ->
        {:ok, Map.put(params, "token", token)}
      {:error, _} ->
        {:error, {:unprocessable_entity, %{token: ["Token creation failed"]}}}
    end
  end
  defp create_reset_token({:error, {_status, _errors} = opts}),
    do: {:error, opts}

  defp deliver_email(%{"user" => user, "token" => token} = params) do
    recover_password_url = String.replace((Map.get(@front_end, :base) <>
      Map.get(@front_end, :reset_password_path)), "{{reset_token}}",
      token.value)
    EmailChannel.deliver([user.email], :recover_password,
      %{identity: user.email, recover_password_url: recover_password_url})
    params
  end
  defp deliver_email({:error, {_status, _errors} = opts}),
    do: {:error, opts}
end
