defmodule FangornSentinelWeb.Router do
  use FangornSentinelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FangornSentinelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug FangornSentinelWeb.Context
  end

  scope "/", FangornSentinelWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # GraphQL API (for mobile apps)
  scope "/api" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug,
      schema: FangornSentinelWeb.GraphQL.Schema

    if Application.compile_env(:fangorn_sentinel, :dev_routes) do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: FangornSentinelWeb.GraphQL.Schema,
        interface: :playground
    end
  end

  # REST API routes
  scope "/api/v1", FangornSentinelWeb.API.V1 do
    pipe_through :api

    # Webhook endpoints
    post "/webhooks/grafana", WebhookController, :grafana

    # Device registration (for mobile apps)
    post "/devices/register", DeviceController, :register
    delete "/devices/unregister", DeviceController, :unregister

    # Schedule management
    resources "/schedules", ScheduleController, except: [:new, :edit] do
      get "/on-call", ScheduleController, :who_is_on_call
      post "/rotations", ScheduleController, :create_rotation
      get "/overrides", ScheduleController, :list_overrides
      post "/overrides", ScheduleController, :create_override
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:fangorn_sentinel, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FangornSentinelWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
