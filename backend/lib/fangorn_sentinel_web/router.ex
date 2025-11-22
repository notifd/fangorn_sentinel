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

  scope "/", FangornSentinelWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes
  scope "/api/v1", FangornSentinelWeb.API.V1 do
    pipe_through :api

    # Webhook endpoints
    post "/webhooks/grafana", WebhookController, :grafana

    # Device registration (for mobile apps)
    post "/devices/register", DeviceController, :register
    delete "/devices/unregister", DeviceController, :unregister
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
