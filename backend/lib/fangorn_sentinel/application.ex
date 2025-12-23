defmodule FangornSentinel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        FangornSentinelWeb.Telemetry,
        FangornSentinel.Repo,
        {DNSCluster, query: Application.get_env(:fangorn_sentinel, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: FangornSentinel.PubSub},
        # Start Oban for background job processing
        {Oban, Application.fetch_env!(:fangorn_sentinel, Oban)}
      ]
      # Add push notification services if configured
      |> maybe_add_goth()
      |> maybe_add_fcm()
      |> maybe_add_apns()
      |> Kernel.++([
        # Start to serve requests, typically the last entry
        FangornSentinelWeb.Endpoint
      ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FangornSentinel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Add Goth for FCM authentication if FCM is configured
  defp maybe_add_goth(children) do
    case Application.get_env(:fangorn_sentinel, FangornSentinel.Push.Goth) do
      nil -> children
      config -> children ++ [{Goth, Keyword.put(config, :name, FangornSentinel.Push.Goth)}]
    end
  end

  # Add FCM dispatcher if configured
  defp maybe_add_fcm(children) do
    case Application.get_env(:fangorn_sentinel, FangornSentinel.Push.FCMDispatcher) do
      nil -> children
      _config -> children ++ [FangornSentinel.Push.FCMDispatcher]
    end
  end

  # Add APNs dispatcher if configured
  defp maybe_add_apns(children) do
    case Application.get_env(:fangorn_sentinel, FangornSentinel.Push.APNSDispatcher) do
      nil -> children
      _config -> children ++ [FangornSentinel.Push.APNSDispatcher]
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FangornSentinelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
