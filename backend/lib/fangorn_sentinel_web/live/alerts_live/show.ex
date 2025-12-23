defmodule FangornSentinelWeb.AlertsLive.Show do
  @moduledoc """
  Alert detail LiveView with acknowledge/resolve actions.
  """
  use FangornSentinelWeb, :live_view

  import FangornSentinelWeb.DashboardComponents

  alias FangornSentinel.Alerts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(FangornSentinel.PubSub, "alert:#{id}")
    end

    case Alerts.get_alert(id) do
      {:ok, alert} ->
        socket =
          socket
          |> assign(:page_title, alert.title)
          |> assign(:current_path, "/alerts/#{id}")
          |> assign(:alert, alert)
          |> assign(:show_ack_modal, false)
          |> assign(:show_resolve_modal, false)
          |> assign(:note, "")

        {:ok, socket}

      {:error, :not_found} ->
        socket =
          socket
          |> put_flash(:error, "Alert not found")
          |> redirect(to: ~p"/alerts")

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("show_ack_modal", _params, socket) do
    {:noreply, assign(socket, :show_ack_modal, true)}
  end

  def handle_event("hide_ack_modal", _params, socket) do
    {:noreply, assign(socket, show_ack_modal: false, note: "")}
  end

  def handle_event("show_resolve_modal", _params, socket) do
    {:noreply, assign(socket, :show_resolve_modal, true)}
  end

  def handle_event("hide_resolve_modal", _params, socket) do
    {:noreply, assign(socket, show_resolve_modal: false, note: "")}
  end

  def handle_event("update_note", %{"note" => note}, socket) do
    {:noreply, assign(socket, :note, note)}
  end

  def handle_event("acknowledge", _params, socket) do
    alert = socket.assigns.alert
    # Use a mock user for now - in production this would come from session
    user = %{id: 1, name: "Current User"}

    case Alerts.acknowledge_alert(alert, user, socket.assigns.note) do
      {:ok, updated_alert} ->
        # Broadcast update
        Phoenix.PubSub.broadcast(FangornSentinel.PubSub, "alerts", {:alert_updated, updated_alert})

        socket =
          socket
          |> assign(:alert, updated_alert)
          |> assign(:show_ack_modal, false)
          |> assign(:note, "")
          |> put_flash(:info, "Alert acknowledged")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to acknowledge alert")}
    end
  end

  def handle_event("resolve", _params, socket) do
    alert = socket.assigns.alert
    user = %{id: 1, name: "Current User"}

    case Alerts.resolve_alert(alert, user, socket.assigns.note) do
      {:ok, updated_alert} ->
        Phoenix.PubSub.broadcast(FangornSentinel.PubSub, "alerts", {:alert_updated, updated_alert})

        socket =
          socket
          |> assign(:alert, updated_alert)
          |> assign(:show_resolve_modal, false)
          |> assign(:note, "")
          |> put_flash(:info, "Alert resolved")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve alert")}
    end
  end

  @impl true
  def handle_info({:alert_updated, updated_alert}, socket) do
    if updated_alert.id == socket.assigns.alert.id do
      {:noreply, assign(socket, :alert, updated_alert)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <div class="flex items-center gap-2 mb-2">
            <a href={~p"/alerts"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="w-4 h-4" />
              Back
            </a>
          </div>
          <h1 class="text-2xl font-bold">{@alert.title}</h1>
          <div class="flex flex-wrap gap-2 mt-2">
            <.severity_badge severity={@alert.severity} />
            <.status_badge status={@alert.status} />
            <span class="badge badge-ghost">{@alert.source}</span>
          </div>
        </div>

        <div class="flex gap-2">
          <button
            :if={@alert.status == :firing}
            phx-click="show_ack_modal"
            class="btn btn-warning btn-sm"
          >
            <.icon name="hero-hand-raised" class="w-4 h-4" />
            Acknowledge
          </button>
          <button
            :if={@alert.status in [:firing, :acknowledged]}
            phx-click="show_resolve_modal"
            class="btn btn-success btn-sm"
          >
            <.icon name="hero-check-circle" class="w-4 h-4" />
            Resolve
          </button>
        </div>
      </div>

      <!-- Alert Details -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <!-- Message -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title text-lg">Message</h2>
              <p class="whitespace-pre-wrap">{@alert.message || "No message"}</p>
            </div>
          </div>

          <!-- Labels -->
          <div :if={@alert.labels && map_size(@alert.labels) > 0} class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title text-lg">Labels</h2>
              <div class="flex flex-wrap gap-2">
                <span :for={{key, value} <- @alert.labels} class="badge badge-outline">
                  {key}: {value}
                </span>
              </div>
            </div>
          </div>

          <!-- Annotations -->
          <div :if={@alert.annotations && map_size(@alert.annotations) > 0} class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title text-lg">Annotations</h2>
              <dl class="space-y-2">
                <div :for={{key, value} <- @alert.annotations} class="flex flex-col">
                  <dt class="text-sm font-medium text-base-content/60">{key}</dt>
                  <dd class="text-sm">{value}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Timeline -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title text-lg">Timeline</h2>
              <ul class="timeline timeline-vertical timeline-compact">
                <li>
                  <div class="timeline-start text-xs text-base-content/60">
                    {format_datetime(@alert.fired_at)}
                  </div>
                  <div class="timeline-middle">
                    <.icon name="hero-fire" class="w-4 h-4 text-error" />
                  </div>
                  <div class="timeline-end timeline-box">Fired</div>
                  <hr :if={@alert.acknowledged_at || @alert.resolved_at} />
                </li>
                <li :if={@alert.acknowledged_at}>
                  <hr />
                  <div class="timeline-start text-xs text-base-content/60">
                    {format_datetime(@alert.acknowledged_at)}
                  </div>
                  <div class="timeline-middle">
                    <.icon name="hero-hand-raised" class="w-4 h-4 text-warning" />
                  </div>
                  <div class="timeline-end timeline-box">Acknowledged</div>
                  <hr :if={@alert.resolved_at} />
                </li>
                <li :if={@alert.resolved_at}>
                  <hr />
                  <div class="timeline-start text-xs text-base-content/60">
                    {format_datetime(@alert.resolved_at)}
                  </div>
                  <div class="timeline-middle">
                    <.icon name="hero-check-circle" class="w-4 h-4 text-success" />
                  </div>
                  <div class="timeline-end timeline-box">Resolved</div>
                </li>
              </ul>
            </div>
          </div>

          <!-- Details -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title text-lg">Details</h2>
              <dl class="space-y-3">
                <div>
                  <dt class="text-sm text-base-content/60">Alert ID</dt>
                  <dd class="font-mono text-sm">{@alert.id}</dd>
                </div>
                <div :if={@alert.source_id}>
                  <dt class="text-sm text-base-content/60">Source ID</dt>
                  <dd class="font-mono text-sm truncate">{@alert.source_id}</dd>
                </div>
                <div :if={@alert.assigned_to_id}>
                  <dt class="text-sm text-base-content/60">Assigned To</dt>
                  <dd class="text-sm">User #{@alert.assigned_to_id}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </div>

      <!-- Acknowledge Modal -->
      <div :if={@show_ack_modal} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg">Acknowledge Alert</h3>
          <p class="py-4">Add an optional note for this acknowledgement.</p>
          <div class="form-control">
            <textarea
              class="textarea textarea-bordered"
              placeholder="Optional note..."
              phx-change="update_note"
              name="note"
            >{@note}</textarea>
          </div>
          <div class="modal-action">
            <button class="btn btn-ghost" phx-click="hide_ack_modal">Cancel</button>
            <button class="btn btn-warning" phx-click="acknowledge">Acknowledge</button>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="hide_ack_modal"></div>
      </div>

      <!-- Resolve Modal -->
      <div :if={@show_resolve_modal} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg">Resolve Alert</h3>
          <p class="py-4">Add an optional resolution note.</p>
          <div class="form-control">
            <textarea
              class="textarea textarea-bordered"
              placeholder="Resolution note..."
              phx-change="update_note"
              name="note"
            >{@note}</textarea>
          </div>
          <div class="modal-action">
            <button class="btn btn-ghost" phx-click="hide_resolve_modal">Cancel</button>
            <button class="btn btn-success" phx-click="resolve">Resolve</button>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="hide_resolve_modal"></div>
      </div>
    </div>
    """
  end

  defp format_datetime(nil), do: "-"
  defp format_datetime(datetime) do
    datetime
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)
  end
end
