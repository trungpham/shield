defmodule Shield.Endpoint do
  use Phoenix.Endpoint, otp_app: :shield

  @cors_origins Application.get_env(:shield, :cors_origins)
                |> String.replace(~r/([\s]+)/, "")
                |> String.split(",", trim: true)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :shield, gzip: true
    # only: ~w(public css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  if Application.get_env(:shield, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_shield_key",
    signing_salt: System.get_env("SECRET_SIGNING_SALT") || "VqDRd89R"

  plug CORSPlug, origin: @cors_origins

  plug Shield.Router

end
