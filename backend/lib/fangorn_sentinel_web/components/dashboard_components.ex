defmodule FangornSentinelWeb.DashboardComponents do
  @moduledoc """
  Dashboard-specific UI components for navigation, sidebar, and layout.
  """
  use Phoenix.Component
  use FangornSentinelWeb, :verified_routes

  import FangornSentinelWeb.CoreComponents

  @doc """
  Renders the dashboard sidebar navigation.
  """
  attr :current_path, :string, default: "/"
  attr :class, :string, default: nil

  def sidebar(assigns) do
    ~H"""
    <aside class={[
      "flex flex-col w-64 bg-base-200 min-h-screen",
      @class
    ]}>
      <div class="p-4 border-b border-base-300">
        <a href="/" class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
            <.icon name="hero-bell-alert" class="w-5 h-5 text-primary-content" />
          </div>
          <span class="text-lg font-bold">Fangorn Sentinel</span>
        </a>
      </div>

      <nav class="flex-1 p-4">
        <ul class="menu menu-md gap-1">
          <li>
            <.nav_link path={~p"/"} current_path={@current_path} icon="hero-home">
              Dashboard
            </.nav_link>
          </li>
          <li>
            <.nav_link path={~p"/alerts"} current_path={@current_path} icon="hero-bell-alert">
              Alerts
            </.nav_link>
          </li>
          <li>
            <.nav_link path={~p"/schedules"} current_path={@current_path} icon="hero-calendar-days">
              Schedules
            </.nav_link>
          </li>
          <li>
            <.nav_link path={~p"/escalations"} current_path={@current_path} icon="hero-arrow-trending-up">
              Escalations
            </.nav_link>
          </li>
          <li>
            <.nav_link path={~p"/teams"} current_path={@current_path} icon="hero-user-group">
              Teams
            </.nav_link>
          </li>
        </ul>

        <div class="divider"></div>

        <ul class="menu menu-md gap-1">
          <li>
            <.nav_link path={~p"/integrations"} current_path={@current_path} icon="hero-puzzle-piece">
              Integrations
            </.nav_link>
          </li>
          <li>
            <.nav_link path={~p"/settings"} current_path={@current_path} icon="hero-cog-6-tooth">
              Settings
            </.nav_link>
          </li>
        </ul>
      </nav>

      <div class="p-4 border-t border-base-300">
        <div class="flex items-center gap-3">
          <div class="avatar placeholder">
            <div class="bg-neutral text-neutral-content rounded-full w-10">
              <span class="text-sm">US</span>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium truncate">User Name</p>
            <p class="text-xs text-base-content/60 truncate">user@example.com</p>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  @doc """
  Renders a navigation link with active state.
  """
  attr :path, :string, required: true
  attr :current_path, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  def nav_link(assigns) do
    active = assigns.current_path == assigns.path ||
             (assigns.path != "/" && String.starts_with?(assigns.current_path, assigns.path))

    assigns = assign(assigns, :active, active)

    ~H"""
    <a href={@path} class={[@active && "active"]}>
      <.icon name={@icon} class="w-5 h-5" />
      {render_slot(@inner_block)}
    </a>
    """
  end

  @doc """
  Renders the mobile navigation drawer.
  """
  attr :current_path, :string, default: "/"

  def mobile_drawer(assigns) do
    ~H"""
    <div class="drawer-side z-50">
      <label for="mobile-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
      <.sidebar current_path={@current_path} class="!min-h-full" />
    </div>
    """
  end

  @doc """
  Renders the top navigation bar for mobile.
  """
  attr :title, :string, default: "Dashboard"

  def mobile_navbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 lg:hidden border-b border-base-300">
      <div class="flex-none">
        <label for="mobile-drawer" class="btn btn-square btn-ghost drawer-button">
          <.icon name="hero-bars-3" class="w-6 h-6" />
        </label>
      </div>
      <div class="flex-1">
        <span class="text-lg font-bold">{@title}</span>
      </div>
      <div class="flex-none">
        <button class="btn btn-square btn-ghost">
          <.icon name="hero-bell" class="w-6 h-6" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders alert status badge.
  """
  attr :status, :atom, required: true

  def status_badge(assigns) do
    {class, text} = case assigns.status do
      :firing -> {"badge-error", "Firing"}
      :acknowledged -> {"badge-warning", "Acknowledged"}
      :resolved -> {"badge-success", "Resolved"}
      _ -> {"badge-ghost", "Unknown"}
    end

    assigns = assign(assigns, class: class, text: text)

    ~H"""
    <span class={["badge", @class]}>{@text}</span>
    """
  end

  @doc """
  Renders alert severity badge.
  """
  attr :severity, :atom, required: true

  def severity_badge(assigns) do
    {class, text} = case assigns.severity do
      :critical -> {"badge-error", "Critical"}
      :warning -> {"badge-warning", "Warning"}
      :info -> {"badge-info", "Info"}
      _ -> {"badge-ghost", "Unknown"}
    end

    assigns = assign(assigns, class: class, text: text)

    ~H"""
    <span class={["badge badge-outline", @class]}>{@text}</span>
    """
  end

  @doc """
  Renders a stat card for the dashboard.
  """
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :description, :string, default: nil
  attr :icon, :string, default: nil
  attr :class, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class={["stat bg-base-100 rounded-box shadow", @class]}>
      <div :if={@icon} class="stat-figure text-primary">
        <.icon name={@icon} class="w-8 h-8" />
      </div>
      <div class="stat-title">{@title}</div>
      <div class="stat-value">{@value}</div>
      <div :if={@description} class="stat-desc">{@description}</div>
    </div>
    """
  end
end
