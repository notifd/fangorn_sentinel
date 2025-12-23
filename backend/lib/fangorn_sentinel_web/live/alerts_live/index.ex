defmodule FangornSentinelWeb.AlertsLive.Index do
  @moduledoc """
  Alerts list LiveView with filtering, search, pagination, and real-time updates.
  """
  use FangornSentinelWeb, :live_view

  import FangornSentinelWeb.DashboardComponents

  alias FangornSentinel.Alerts

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(FangornSentinel.PubSub, "alerts")
    end

    socket =
      socket
      |> assign(:page_title, "Alerts")
      |> assign(:current_path, "/alerts")
      |> assign(:filters, %{status: nil, severity: nil, search: ""})
      |> assign(:sort_by, :fired_at)
      |> assign(:sort_order, :desc)
      |> assign(:page, 1)
      |> assign(:per_page, @per_page)
      |> load_alerts()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filters = %{
      status: params["status"],
      severity: params["severity"],
      search: params["search"] || ""
    }

    page = String.to_integer(params["page"] || "1")

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, page)
      |> load_alerts()

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    filters = %{
      status: empty_to_nil(filter_params["status"]),
      severity: empty_to_nil(filter_params["severity"]),
      search: filter_params["search"] || ""
    }

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> load_alerts()
      |> push_patch_with_filters()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:filters, %{status: nil, severity: nil, search: ""})
      |> assign(:page, 1)
      |> load_alerts()
      |> push_patch(to: ~p"/alerts")

    {:noreply, socket}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    field = String.to_existing_atom(field)

    {sort_by, sort_order} =
      if socket.assigns.sort_by == field do
        {field, toggle_order(socket.assigns.sort_order)}
      else
        {field, :desc}
      end

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_order, sort_order)
      |> load_alerts()

    {:noreply, socket}
  end

  def handle_event("page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    socket =
      socket
      |> assign(:page, page)
      |> load_alerts()
      |> push_patch_with_filters()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:alert_created, _alert}, socket) do
    {:noreply, load_alerts(socket)}
  end

  def handle_info({:alert_updated, _alert}, socket) do
    {:noreply, load_alerts(socket)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp load_alerts(socket) do
    %{filters: filters, page: page, per_page: per_page} = socket.assigns

    query_opts =
      filters
      |> Map.take([:status, :severity])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.put(:limit, per_page + 1)
      |> Map.put(:offset, (page - 1) * per_page)

    alerts = Alerts.list_alerts(query_opts)

    # Check if there's a next page
    has_next = length(alerts) > per_page
    alerts = Enum.take(alerts, per_page)

    # Apply search filter client-side for now
    alerts =
      if filters.search != "" do
        search_lower = String.downcase(filters.search)
        Enum.filter(alerts, fn alert ->
          String.contains?(String.downcase(alert.title || ""), search_lower) ||
          String.contains?(String.downcase(alert.message || ""), search_lower)
        end)
      else
        alerts
      end

    socket
    |> assign(:alerts, alerts)
    |> assign(:has_next, has_next)
    |> assign(:has_prev, page > 1)
  end

  defp push_patch_with_filters(socket) do
    %{filters: filters, page: page} = socket.assigns

    params =
      %{}
      |> maybe_put(:status, filters.status)
      |> maybe_put(:severity, filters.severity)
      |> maybe_put(:search, if(filters.search != "", do: filters.search))
      |> maybe_put(:page, if(page > 1, do: page))

    push_patch(socket, to: ~p"/alerts?#{params}")
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(val), do: val

  defp toggle_order(:asc), do: :desc
  defp toggle_order(:desc), do: :asc

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold">Alerts</h1>
          <p class="text-base-content/60">Manage and respond to alerts</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="card bg-base-100 shadow">
        <div class="card-body p-4">
          <form phx-change="filter" phx-submit="filter" class="flex flex-wrap gap-4 items-end">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Status</span>
              </label>
              <select name="filters[status]" class="select select-bordered select-sm">
                <option value="">All</option>
                <option value="firing" selected={@filters.status == "firing"}>Firing</option>
                <option value="acknowledged" selected={@filters.status == "acknowledged"}>Acknowledged</option>
                <option value="resolved" selected={@filters.status == "resolved"}>Resolved</option>
              </select>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Severity</span>
              </label>
              <select name="filters[severity]" class="select select-bordered select-sm">
                <option value="">All</option>
                <option value="critical" selected={@filters.severity == "critical"}>Critical</option>
                <option value="warning" selected={@filters.severity == "warning"}>Warning</option>
                <option value="info" selected={@filters.severity == "info"}>Info</option>
              </select>
            </div>

            <div class="form-control flex-1 min-w-[200px]">
              <label class="label">
                <span class="label-text">Search</span>
              </label>
              <input
                type="text"
                name="filters[search]"
                value={@filters.search}
                placeholder="Search alerts..."
                class="input input-bordered input-sm"
                phx-debounce="300"
              />
            </div>

            <button
              type="button"
              phx-click="clear_filters"
              class="btn btn-ghost btn-sm"
              disabled={@filters.status == nil && @filters.severity == nil && @filters.search == ""}
            >
              Clear
            </button>
          </form>
        </div>
      </div>

      <!-- Alert List -->
      <div class="card bg-base-100 shadow">
        <div class="card-body p-0">
          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th class="cursor-pointer hover:bg-base-200" phx-click="sort" phx-value-field="severity">
                    Severity
                    <.sort_indicator field={:severity} sort_by={@sort_by} sort_order={@sort_order} />
                  </th>
                  <th class="cursor-pointer hover:bg-base-200" phx-click="sort" phx-value-field="title">
                    Title
                    <.sort_indicator field={:title} sort_by={@sort_by} sort_order={@sort_order} />
                  </th>
                  <th class="cursor-pointer hover:bg-base-200" phx-click="sort" phx-value-field="status">
                    Status
                    <.sort_indicator field={:status} sort_by={@sort_by} sort_order={@sort_order} />
                  </th>
                  <th>Source</th>
                  <th class="cursor-pointer hover:bg-base-200" phx-click="sort" phx-value-field="fired_at">
                    Fired At
                    <.sort_indicator field={:fired_at} sort_by={@sort_by} sort_order={@sort_order} />
                  </th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={alert <- @alerts} class="hover">
                  <td><.severity_badge severity={alert.severity} /></td>
                  <td class="max-w-md">
                    <a href={~p"/alerts/#{alert.id}"} class="link link-hover font-medium">
                      {alert.title}
                    </a>
                    <p :if={alert.message} class="text-sm text-base-content/60 truncate max-w-xs">
                      {alert.message}
                    </p>
                  </td>
                  <td><.status_badge status={alert.status} /></td>
                  <td class="text-sm">{alert.source}</td>
                  <td class="text-sm text-base-content/60">{format_datetime(alert.fired_at)}</td>
                  <td>
                    <div class="flex gap-1">
                      <a href={~p"/alerts/#{alert.id}"} class="btn btn-ghost btn-xs">
                        View
                      </a>
                    </div>
                  </td>
                </tr>
                <tr :if={@alerts == []}>
                  <td colspan="6" class="text-center py-8 text-base-content/60">
                    No alerts found
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div class="flex justify-between items-center p-4 border-t border-base-200">
            <div class="text-sm text-base-content/60">
              Page {@page}
            </div>
            <div class="join">
              <button
                class="join-item btn btn-sm"
                phx-click="page"
                phx-value-page={@page - 1}
                disabled={!@has_prev}
              >
                Previous
              </button>
              <button
                class="join-item btn btn-sm"
                phx-click="page"
                phx-value-page={@page + 1}
                disabled={!@has_next}
              >
                Next
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp sort_indicator(assigns) do
    ~H"""
    <span :if={@sort_by == @field} class="ml-1">
      <%= if @sort_order == :asc, do: "↑", else: "↓" %>
    </span>
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
