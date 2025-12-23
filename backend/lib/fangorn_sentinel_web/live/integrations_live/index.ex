defmodule FangornSentinelWeb.IntegrationsLive.Index do
  @moduledoc """
  Integrations LiveView - placeholder.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Integrations")
      |> assign(:current_path, "/integrations")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Integrations</h1>
        <p class="text-base-content/60">Connect external services</p>
      </div>

      <div class="alert alert-info">
        <span>Integrations interface coming soon</span>
      </div>
    </div>
    """
  end
end
