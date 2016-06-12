defmodule Shield.Router do
  use Shield.Web, :router

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
end
