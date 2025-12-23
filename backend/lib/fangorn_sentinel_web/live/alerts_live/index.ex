defmodule FangornSentinelWeb.AlertsLive.Index do
  @moduledoc """
  Alerts list LiveView - placeholder for Issue #24.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Alerts")
      |> assign(:current_path, "/alerts")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Alerts</h1>
        <p class="text-base-content/60">Manage and respond to alerts</p>
      </div>

      <div class="alert alert-info">
        <span>Alert management interface coming soon (Issue #24)</span>
      </div>
    </div>
    """
  end
end
