defmodule FangornSentinelWeb.SettingsLive.Index do
  @moduledoc """
  Settings LiveView - placeholder.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Settings")
      |> assign(:current_path, "/settings")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Settings</h1>
        <p class="text-base-content/60">Configure your preferences</p>
      </div>

      <div class="alert alert-info">
        <span>Settings interface coming soon</span>
      </div>
    </div>
    """
  end
end
