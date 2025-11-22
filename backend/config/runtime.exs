import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/fangorn_sentinel start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :fangorn_sentinel, FangornSentinelWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :fangorn_sentinel, FangornSentinel.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :fangorn_sentinel, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :fangorn_sentinel, FangornSentinelWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :fangorn_sentinel, FangornSentinelWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :fangorn_sentinel, FangornSentinelWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :fangorn_sentinel, FangornSentinel.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  # APNs Configuration (iOS Push Notifications)
  # Requires:
  # - APNS_KEY_ID: Your Apple Developer key ID (e.g., "ABC123DEFG")
  # - APNS_TEAM_ID: Your Apple Team ID (e.g., "DEF123")
  # - APNS_KEY_PATH: Path to .p8 key file (default: /app/config/AuthKey.p8)
  if System.get_env("APNS_KEY_ID") do
    config :pigeon, :apns,
      fangorn_apns: %{
        key: System.get_env("APNS_KEY_PATH") || "/app/config/AuthKey.p8",
        key_identifier: System.get_env("APNS_KEY_ID"),
        team_id: System.get_env("APNS_TEAM_ID"),
        mode: :prod,
        # For development/sandbox, use: mode: :dev
        topic: "com.notifd.fangornsentinel"
      }
  end

  # FCM Configuration (Android Push Notifications)
  # Requires:
  # - FCM_PROJECT_ID: Your Firebase project ID
  # - FCM_SERVICE_ACCOUNT_JSON_PATH: Path to service account JSON (default: /app/config/fcm-service-account.json)
  if System.get_env("FCM_PROJECT_ID") do
    config :pigeon, :fcm_v1,
      fangorn_fcm: %{
        project_id: System.get_env("FCM_PROJECT_ID"),
        service_account_json: System.get_env("FCM_SERVICE_ACCOUNT_JSON_PATH") || "/app/config/fcm-service-account.json"
      }
  end

  # SMTP Email configuration
  config :fangorn_sentinel, FangornSentinel.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_RELAY") || "smtp.sendgrid.net",
    port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
    username: System.get_env("SMTP_USERNAME"),
    password: System.get_env("SMTP_PASSWORD"),
    tls: :always,
    auth: :always

  # Oban queue configuration
  config :fangorn_sentinel, Oban,
    repo: FangornSentinel.Repo,
    plugins: [
      {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
      {Oban.Plugins.Cron, crontab: []}
    ],
    queues: [
      alerts: String.to_integer(System.get_env("OBAN_ALERTS_CONCURRENCY") || "50"),
      escalations: String.to_integer(System.get_env("OBAN_ESCALATIONS_CONCURRENCY") || "25"),
      notifications: String.to_integer(System.get_env("OBAN_NOTIFICATIONS_CONCURRENCY") || "100"),
      default: String.to_integer(System.get_env("OBAN_DEFAULT_CONCURRENCY") || "10")
    ]
end
