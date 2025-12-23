defmodule FangornSentinelWeb.DashboardLive.Index do
  @moduledoc """
  Main dashboard LiveView showing alert overview and stats.
  """
  use FangornSentinelWeb, :live_view

  import FangornSentinelWeb.DashboardComponents

  alias FangornSentinel.Alerts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to alert updates for real-time
      Phoenix.PubSub.subscribe(FangornSentinel.PubSub, "alerts")
    end

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:current_path, "/")
      |> load_stats()
      |> load_recent_alerts()

    {:ok, socket}
  end

  @impl true
  def handle_info({:alert_created, _alert}, socket) do
    socket =
      socket
      |> load_stats()
      |> load_recent_alerts()

    {:noreply, socket}
  end

  def handle_info({:alert_updated, _alert}, socket) do
    socket =
      socket
      |> load_stats()
      |> load_recent_alerts()

    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp load_stats(socket) do
    # Count alerts by status
    firing_count = length(Alerts.list_alerts(status: "firing", limit: 1000))
    acknowledged_count = length(Alerts.list_alerts(status: "acknowledged", limit: 1000))
    resolved_today = length(Alerts.list_alerts(status: "resolved", limit: 100))

    socket
    |> assign(:firing_count, firing_count)
    |> assign(:acknowledged_count, acknowledged_count)
    |> assign(:resolved_today, resolved_today)
  end

  defp load_recent_alerts(socket) do
    recent_alerts = Alerts.list_alerts(limit: 5)
    assign(socket, :recent_alerts, recent_alerts)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <p class="text-base-content/60">Overview of your on-call system</p>
      </div>

      <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
        <.stat_card
          title="Firing Alerts"
          value={@firing_count}
          description="Require immediate attention"
          icon="hero-fire"
        />
        <.stat_card
          title="Acknowledged"
          value={@acknowledged_count}
          description="Being worked on"
          icon="hero-clock"
        />
        <.stat_card
          title="Resolved Today"
          value={@resolved_today}
          description="Successfully handled"
          icon="hero-check-circle"
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-bell-alert" class="w-5 h-5" />
              Recent Alerts
            </h2>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Severity</th>
                    <th>Status</th>
                    <th>Time</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={alert <- @recent_alerts} class="hover">
                    <td class="max-w-xs truncate">{alert.title}</td>
                    <td><.severity_badge severity={alert.severity} /></td>
                    <td><.status_badge status={alert.status} /></td>
                    <td class="text-xs text-base-content/60">
                      {format_time(alert.fired_at)}
                    </td>
                  </tr>
                  <tr :if={@recent_alerts == []}>
                    <td colspan="4" class="text-center text-base-content/60">
                      No alerts yet
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="card-actions justify-end">
              <a href={~p"/alerts"} class="btn btn-primary btn-sm">
                View All Alerts
              </a>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-user-group" class="w-5 h-5" />
              On-Call Now
            </h2>

            <div class="py-4">
              <div class="flex items-center gap-4">
                <div class="avatar placeholder">
                  <div class="bg-primary text-primary-content rounded-full w-12">
                    <span>OC</span>
                  </div>
                </div>
                <div>
                  <p class="font-medium">On-Call User</p>
                  <p class="text-sm text-base-content/60">Primary responder</p>
                </div>
              </div>
            </div>

            <div class="card-actions justify-end">
              <a href={~p"/schedules"} class="btn btn-ghost btn-sm">
                View Schedule
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">
            <.icon name="hero-chart-bar" class="w-5 h-5" />
            Quick Actions
          </h2>

          <div class="flex flex-wrap gap-2">
            <a href={~p"/alerts"} class="btn btn-outline btn-sm">
              <.icon name="hero-bell" class="w-4 h-4" />
              View Alerts
            </a>
            <a href={~p"/schedules"} class="btn btn-outline btn-sm">
              <.icon name="hero-calendar" class="w-4 h-4" />
              Manage Schedules
            </a>
            <a href={~p"/escalations"} class="btn btn-outline btn-sm">
              <.icon name="hero-arrow-trending-up" class="w-4 h-4" />
              Escalation Policies
            </a>
            <a href={~p"/integrations"} class="btn btn-outline btn-sm">
              <.icon name="hero-puzzle-piece" class="w-4 h-4" />
              Integrations
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_time(nil), do: "-"
  defp format_time(datetime) do
    datetime
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)
  end
end
