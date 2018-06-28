defmodule CoreWeb.Router do
  use CoreWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CoreWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/", PageController, :save
    post "/call", PageController, :sendcall
  end

  scope "/mqauth", CoreWeb do
    pipe_through :api

    get "/user", MqAuthController, :user
    get "/vhost", MqAuthController, :vhost
    get "/resource", MqAuthController, :resource
    get "/topic", MqAuthController, :topic
  end

  # Other scopes may use custom stacks.
  scope "/api", CoreWeb do
    pipe_through :api

    get "/discovery", DiscoveryController, :index
  end
end
