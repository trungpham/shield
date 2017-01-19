use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shield, Shield.Endpoint,
  http: [port: 4001],
  server: false

config :shield, sql_sandbox: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :authable, Authable.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env["DATABASE_POSTGRESQL_USERNAME"] || "postgres",
  password: System.get_env["DATABASE_POSTGRESQL_PASSWORD"] || "",
  database: "shield_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :shield_notifier, Shield.Notifier.Mailer,
  adapter: Bamboo.TestAdapter
