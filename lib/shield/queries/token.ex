defmodule Shield.Query.Token do
  @moduledoc """
  Query builder for Authable.Token Model
  """

  import Ecto.Query

  @token_store Application.get_env(:authable, :token_store)

  @doc """
  Query for Token for reset token
  """
  def valid_reset_token(reset_token_value) do
    (from t in @token_store,
      where: t.value == ^reset_token_value and
        t.name == "reset_token" and
        t.expires_at > ^:os.system_time(:seconds),
      preload: [:user],
      limit: 1)
  end
end
