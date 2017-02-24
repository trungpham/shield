defmodule Shield.Policy.User.ResetPassword do
  @moduledoc """
  User.ResetPassword policy
  """

  alias Shield.Query.Token, as: TokenQuery

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)

  @doc """
  Runs password reset process for given params
  - Deletes session token
  """
  def process(params) do
    params
    |> validate_reset_token()
    |> delete_reset_token()
    |> change_password()
  end

  defp validate_reset_token(%{"reset_token" => reset_token} = params) do
    token =
      reset_token
      |> TokenQuery.valid_reset_token()
      |> @repo.get_by([])

    case token do
      nil ->
        {:error, {:forbidden, %{reset_token: "Invalid token."}}}
      _ ->
        {:ok, Map.put(params, "token", token)}
    end
  end

  defp delete_reset_token({:ok, %{"token" => token} = params}) do
    @repo.delete!(token)
    {:ok, params}
  end
  defp delete_reset_token({:error, {_status, _errors} = opts}),
    do: {:error, opts}

  defp change_password({:ok, %{"token" => token, "password" => password} = params}) do
    changeset = @user.password_changeset(token.user, %{password: password})
    case @repo.update(changeset) do
      {:ok, _} -> {:ok, params}
      {:error, changeset} -> {:error, {:unprocessable_entity, changeset}}
    end
  end
  defp change_password({:error, {_status, _errors} = opts}),
    do: {:error, opts}
end
