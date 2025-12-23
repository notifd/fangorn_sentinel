defmodule FangornSentinelWeb.EscalationsLive.Index do
  @moduledoc """
  Escalations LiveView - placeholder.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Escalation Policies")
      |> assign(:current_path, "/escalations")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Escalation Policies</h1>
        <p class="text-base-content/60">Configure alert escalation workflows</p>
      </div>

      <div class="alert alert-info">
        <span>Escalation policy interface coming soon</span>
      </div>
    </div>
    """
  end
end
