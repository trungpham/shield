# Shield

Shield is an OAuth2 Provider hex package and also a standalone microservice build top of the Phoenix Framework and 'authable' package.

Shield can be used inside an application or can be used as standalone microservice. Shield simply plays role of the 'authorization server' on OAuth2 scheme.

## Installation

### As Package

The package can be installed as:

  1. Add shield to your list of dependencies in `mix.exs` and run `mix deps.get
`:

        def deps do
          [{:shield, "~> 0.1.1"}]
        end

  2. Ensure shield is started before your application:

        def application do
          [applications: [:shield]]
        end

  3. Add authable configurations to your `config/config.exs` file:

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
          renderer: Authable.Rederer.RestApi

  4. Add shield configurations to your `config/config.exs` file:

        config :shield,
          views: %{
            changeset: Shield.ChangesetView,
            error: Shield.ErrorView,
            app: Shield.AppView,
            client: Shield.ClientView,
            token: Shield.TokenView,
            user: Shield.UserView
          },
          cors_origins: ["localhost:4000", "*"]

  If you want to disable a authorization strategy, then delete it from shield configuration.

  If you want to add a new authorization strategy then add your own module.

  5. Use installer to generate controllers, views, models and migrations from originals

        # Run only if you need to change behaviours, otherwise skip this.
        mix shield.install

  6. Add database configurations for the `Authable.Repo` on env config files:

        config :authable, Authable.Repo,
          adapter: Ecto.Adapters.Postgres,
          username: "postgres",
          password: "",
          database: "",
          hostname: "",
          pool_size: 10

  7. Run migrations for Authable.Repo (Note: all id fields are UUID type):

        mix ecto.create
        mix ecto.migrate -r Authable.Repo

  8. Add routes

        pipeline :api do
          plug :accepts, ["json"]
        end

        scope "/", Shield do
          pipe_through :api
          resources "/clients", ClientController, except: [:new, :edit]

          get     "/apps", AppController, :index
          get     "/apps/:id", AppController, :show
          delete  "/apps/:id", AppController, :delete
          post    "/apps/authorize", AppController, :authorize

          get     "/tokens/:id", TokenController, :show
          post    "/tokens", TokenController, :create

          post    "/users/register", UserController, :register
          post    "/users/login", UserController, :login
          delete  "/users/logout", UserController, :logout
          get     "/users/me", UserController, :me
        end

  9. You are ready to go!

### Standalone

        git clone git@github.com:mustafaturan/shield.git
        cd shields
        mix deps.get
        mix ecto.create -r Authable.Repo
        mix ecto.migrate -r Authable.Repo
        mix phoenix.server

### Heroku

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Usage, Examples & Configuration

### Protecting resources

Inside your controller modules; add the following lines to restrict access to actions.

        # Add plug to restrict access to all actions
        plug Authable.Plug.Authenticate [scopes: ~w(read)]

        # Example inside module

        defmodule SomeModule.AppController do
          use SomeModule.Web, :controller
          ...
          plug Authable.Plug.Authenticate [scopes: ~w(read write)]

          def index(conn, _params) do
            # access to current user on successful authentication
            current_user = conn.assigns[:current_user]
            ...
          end

          ...
        end

If you need to restrict specific resource, you may guard with when clause. Forexample, to check authentication only on :create, :update and :delete actions of your controllers.

        plug Authable.Plug.Authenticate [scopes: ~w(read write)] when action in [:create, :update, :delete]

Incase you do not want to allow registered user to access resources:

        # Add plug `Authable.Plug.UnauthorizedOnly` for necessary actions
        plug :Authable.Plug.UnauthorizedOnly when action in [:register]

        # Example inside module

        defmodule SomeModule.AppController do
          use SomeModule.Web, :controller
          ...

          plug Authable.Plug.Authenticate [scopes: ~w(read write)] when action in [:create]
          plug Authable.Plug.UnauthorizedOnly when action in [:register]

          def register(conn, _params) do
            # if user logged in, then will response automatically with
            # unprocessable_entity 422 header and error
            ...
          end

          def create(conn, params) do
            # access to current user on successful authentication
            current_user = conn.assigns[:current_user]
            ...
          end

          ...
        end

Manually handling authentication:

        defmodule SomeModule.AppController do
          use SomeModule.Web, :controller
          ...
          import Authable.Helper

          def register(conn, _params) do
            current_user = authorize_for_resource(conn, ~w(read write))
            if is_nil(current_user) do
              IO.puts "not authencated!"
            else
              IO.puts current_user.email
            end
            ...
          end
        end

### Accessing resource owner info

By default `Authable.Model.User` represents resource owner. To access resource owner, plug `Authable.Plug.Authenticate` must be called. Then current user information will be available by conn assignments.

        conn.assigns[:current_user]

### Views

By default REST style views are used to represent error and data models. In shield configuration, it is possible to change view modules to represent non-rest style data models like JSON-API or any other data model.

## Client Implementations

Since 'shield' application is a microservice. Several client applications might be written using shield. Please do not hesitate to raise an issue with your implementation, description and demo url.

## Contributing

### Issues, Bugs, Documentation, Enhancements

  1. Fork the project

  2. Make your improvements and write your tests.

  3. Document what you did/change.

  4. Make a pull request.

### To add new strategy

Shield and Authable are extensible modules, you can create your strategy and share as hex package(Which can be listed on Wiki pages).

## Todo

  - [ ] Swagger documentation

  - [ ] Background job to delete expired tokens

  - [ ] EmberJS client implementation as a seperate sample app

  - [ ] Sample resource server implementation

## References

https://tools.ietf.org/html/rfc6749

https://github.com/mustafaturan/authable

https://hexdocs.pm/authable
