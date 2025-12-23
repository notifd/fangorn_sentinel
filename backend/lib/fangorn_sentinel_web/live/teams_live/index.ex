defmodule FangornSentinelWeb.TeamsLive.Index do
  @moduledoc """
  Teams LiveView - placeholder.
  """
  use FangornSentinelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Teams")
      |> assign(:current_path, "/teams")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold">Teams</h1>
        <p class="text-base-content/60">Manage teams and members</p>
      </div>

      <div class="alert alert-info">
        <span>Team management interface coming soon</span>
      </div>
    </div>
    """
  end
end
