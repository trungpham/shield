defmodule Shield.Policy.User.ChangePassword do
  @moduledoc """
  User.ChangePassword policy
  """

  alias Authable.Utils.Crypt, as: CryptUtil

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)

  @doc """
  Runs password reset process for given params
  - Deletes session token
  """
  def process(params) do
    params
    |> validate_old_password()
    |> change_password()
  end

  defp validate_old_password(%{"user" => user, "old_password" => old_password} = params) do
    case CryptUtil.match_password(old_password, Map.get(user, :password, "")) do
      false ->
        {:error, {:forbidden, %{old_password: ["Wrong old password."]}}}
      true ->
        params
    end
  end

  defp change_password(%{"user" => user, "password" => password} = params) do
    changeset = @user.password_changeset(user, %{password: password})
    case @repo.update(changeset) do
      {:ok, _} -> {:ok, params}
      {:error, changeset} -> {:error, {:unprocessable_entity, changeset}}
    end
  end
  defp change_password({:error, {_status, _errors} = opts}),
    do: {:error, opts}
end
