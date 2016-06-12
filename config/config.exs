# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :shield, Shield.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "YfOapYVW+HP0fv/xObEFlLQ/nwr3BiUkTy+4WDjRzx7uTV/9b+QAm4TLABZdqLUI",
  render_errors: [accepts: ~w(json), format: "json"]

config :shield,
  authorizations: %{
    headers: %{
      "authorization" => %{
        "Basic" => Authable.Authentications.Basic,
        "Bearer" => Authable.Authentications.Bearer
      },
      "x-api-token" => Authable.Authentications.Bearer
    },
    query_params: %{
      "access_token" => Authable.Authentications.Bearer
    },
    session: %{
      "session_token" => Authable.Authentications.Session
    }
  },
  views: %{
    changeset: Shield.ChangesetView,
    error: Shield.ErrorView,
    app: Shield.AppView,
    client: Shield.ClientView,
    token: Shield.TokenView,
    user: Shield.UserView
  },
  cors_origins: ["localhost:4000", "*"]

config :authable,
  repo: Authable.Repo,
  resource_owner: Authable.Models.User,
  token_store: Authable.Models.Token,
  client: Authable.Models.Client,
  app: Authable.Models.App,
  expires_in: %{
    access_token: 3600,
    refresh_token: 24 * 3600,
    authorization_code: 300,
    session_token: 30 * 24 * 3600
  },
  strategies: %{
    authorization_code: Authable.GrantTypes.AuthorizationCode,
    client_credentials: Authable.GrantTypes.ClientCredentials,
    password: Authable.GrantTypes.Password,
    refresh_token: Authable.GrantTypes.RefreshToken
  },
  scopes: ~w(read write session)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: true
