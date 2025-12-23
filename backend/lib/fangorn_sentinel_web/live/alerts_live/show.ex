defmodule FangornSentinelWeb.AlertsLive.Show do
  @moduledoc """
  Alert detail LiveView - placeholder.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Alert ##{id}")
      |> assign(:current_path, "/alerts/#{id}")
      |> assign(:alert_id, id)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Alert #{@alert_id}</h1>
        <p class="text-base-content/60">Alert details</p>
      </div>

      <div class="alert alert-info">
        <span>Alert detail view coming soon</span>
      </div>
    </div>
    """
  end
end
