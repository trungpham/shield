defmodule Shield.Authorization do
  @moduledoc """
  Automatically imports Shield.Plug module methods.
  """

  defmacro __using__(_) do
    quote do
      import Shield.Plug
    end
  end
end
