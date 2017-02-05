defmodule Shield.Arm do
  @moduledoc """
  A behaviour for all arm modules called by other authable modules.
  """

  @callback defend(conn :: Plug.Conn.t, opts :: any) :: Plug.Conn.t
end
