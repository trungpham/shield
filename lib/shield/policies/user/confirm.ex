defmodule Shield.Policy.User.Confirm do
  @moduledoc """
  User.Confirm policy
  """

  @doc """
  Runs user email confirmation process for given params
  - Confirms user
  """
  def process(%{"confirmation_token" => token_value} = _params) do
    case Shield.Arm.Confirmable.confirm(token_value) do
      {:ok, _} ->
        {:ok, %{messages: "Email confirmed successfully!"}}
      {:error, %{confirmation_token: _} = errors} ->
        {:error, {:forbidden, errors}}
      {:error, changeset} ->
        {:error, {:unprocessable_entity, changeset}}
    end
  end
end
