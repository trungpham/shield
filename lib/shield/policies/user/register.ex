defmodule Shield.Policy.User.Register do
  @moduledoc """
  User.Register policy
  """

  @repo Application.get_env(:authable, :repo)
  @user Application.get_env(:authable, :resource_owner)

  @doc """
  Runs user registration process for given params
  - Creates user
  - Processes confirmable-arm requirements
  """
  def process(params) do
    params
    |> create_user()
    |> process_confirmable_requirements()
  end

  defp create_user(%{"email" => _email, "password" => _password} = params) do
    changeset = @user.registration_changeset(%@user{}, params)

    case @repo.insert(changeset) do
      {:ok, user} -> {:ok, Map.put(params, "user", user)}
      {:error, changeset} -> {:error, {:unprocessable_entity, changeset}}
    end
  end

  defp process_confirmable_requirements({:ok, %{"user" => user} = params}) do
    if Application.get_env(:shield, :confirmable) do
      case Shield.Arm.Confirmable.registration_hook(user) do
        {:ok, token} -> {:ok, Map.put(params, "token", token)}
        {:error, changeset} -> {:error, {:unprocessable_entity, changeset}}
      end
    else
      {:ok, params}
    end
  end
  defp process_confirmable_requirements({:error, {_status, _errors} = opts}),
    do: {:error, opts}
end
