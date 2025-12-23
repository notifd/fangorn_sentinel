# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fangorn_sentinel,
  ecto_repos: [FangornSentinel.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :fangorn_sentinel, FangornSentinelWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FangornSentinelWeb.ErrorHTML, json: FangornSentinelWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FangornSentinel.PubSub,
  live_view: [signing_salt: "SLbOmLLs"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :fangorn_sentinel, FangornSentinel.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  fangorn_sentinel: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  fangorn_sentinel: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian JWT configuration
config :fangorn_sentinel, FangornSentinel.Guardian,
  issuer: "fangorn_sentinel",
  secret_key: "dev_secret_key_change_in_production"

# Push Notifications - iOS/APNs
# To enable APNs, configure in runtime.exs or environment-specific config:
#
# config :fangorn_sentinel, FangornSentinel.Push.APNSDispatcher,
#   adapter: Pigeon.APNS,
#   key: System.get_env("APNS_AUTH_KEY"),      # Contents of AuthKey_XXXXXXXXXX.p8
#   key_identifier: System.get_env("APNS_KEY_ID"),  # XXXXXXXXXX
#   team_id: System.get_env("APNS_TEAM_ID"),   # Your Apple Developer Team ID
#   mode: :prod                                 # :dev for sandbox, :prod for production
#
# config :fangorn_sentinel, :apns_bundle_id, "com.yourcompany.fangornsentinel"

# Push Notifications - Android/FCM
# To enable FCM, configure in runtime.exs or environment-specific config:
#
# First, configure Goth for Google Cloud authentication:
# config :fangorn_sentinel, FangornSentinel.Push.Goth,
#   source: {:service_account, System.get_env("GOOGLE_APPLICATION_CREDENTIALS_JSON") |> Jason.decode!()}
#
# Then configure the FCM dispatcher:
# config :fangorn_sentinel, FangornSentinel.Push.FCMDispatcher,
#   adapter: Pigeon.FCM,
#   project_id: System.get_env("FCM_PROJECT_ID"),
#   auth: FangornSentinel.Push.Goth

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
