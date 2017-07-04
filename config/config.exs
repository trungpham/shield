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
  confirmable: false,
  one_time_password_enabled: false,
  hooks: Shield.Hook.Default,
  views: %{
    changeset: Shield.ChangesetView,
    error: Shield.ErrorView,
    app: Shield.AppView,
    client: Shield.ClientView,
    token: Shield.TokenView,
    user: Shield.UserView
  },
  cors_origins: "http://localhost:8080, *",
  front_end: %{
    base: "http://localhost:8080",
    confirmation_path: "/users/confirm?confirmation_token={{confirmation_token}}",
    reset_password_path: "/users/reset-password?reset_token={{reset_token}}"
  },
  ecto_repos: []

config :authable,
  ecto_repos: [Authable.Repo],
  repo: Authable.Repo,
  resource_owner: Authable.Model.User,
  token_store: Authable.Model.Token,
  client: Authable.Model.Client,
  app: Authable.Model.App,
  expires_in: %{
    access_token: 3600,
    refresh_token: 24 * 3600,
    authorization_code: 300,
    session_token: 30 * 24 * 3600
  },
  grant_types: %{
    authorization_code: Authable.GrantType.AuthorizationCode,
    client_credentials: Authable.GrantType.ClientCredentials,
    password: Authable.GrantType.Password,
    refresh_token: Authable.GrantType.RefreshToken
  },
  auth_strategies: %{
    headers: %{
      "authorization" => [
        {~r/Basic ([a-zA-Z\-_\+=]+)/, Authable.Authentication.Basic},
        {~r/Bearer ([a-zA-Z\-_\+=]+)/, Authable.Authentication.Bearer},
      ],
      "x-api-token" => [
        {~r/([a-zA-Z\-_\+=]+)/, Authable.Authentication.Bearer}
      ]
    },
    query_params: %{
      "access_token" => Authable.Authentication.Bearer
    },
    sessions: %{
      "session_token" => Authable.Authentication.Session
    }
  },
  scopes: ~w(read write session),
  renderer: Authable.Renderer.RestApi

config :shield_notifier,
  channels: %{
    email: %{
      from: %{
        name: {:system, "APP_NAME", "Shield Notifier"},
        email: {:system, "APP_FROM_EMAIL", "no-reply@localhost"}
      }
    }
  }

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
