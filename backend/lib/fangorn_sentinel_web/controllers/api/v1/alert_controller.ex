defmodule FangornSentinelWeb.API.V1.AlertController do
  @moduledoc """
  REST API controller for alert management.

  Provides endpoints for creating, listing, getting, acknowledging,
  and resolving alerts.
  """
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Alerts

  action_fallback FangornSentinelWeb.FallbackController

  @doc """
  Lists alerts with optional filtering.

  ## Query Parameters
    * `status` - Filter by status (firing, acknowledged, resolved)
    * `severity` - Filter by severity (critical, warning, info)
    * `source` - Filter by source (grafana, prometheus, etc.)
    * `limit` - Limit results (default: 50, max: 1000)
    * `offset` - Offset for pagination (default: 0)
  """
  def index(conn, params) do
    filters = %{
      status: params["status"],
      severity: params["severity"],
      source: params["source"],
      limit: parse_integer(params["limit"], 50),
      offset: parse_integer(params["offset"], 0)
    }

    alerts = Alerts.list_alerts(filters)
    render(conn, :index, alerts: alerts)
  end

  @doc """
  Gets a single alert by ID.
  """
  def show(conn, %{"id" => id}) do
    case Alerts.get_alert(id) do
      {:ok, alert} ->
        render(conn, :show, alert: alert)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Alert not found"})
    end
  end

  @doc """
  Creates a new alert.

  ## Request Body
    * `title` - Required. Alert title
    * `severity` - Required. One of: critical, warning, info
    * `source` - Required. Source identifier (e.g., "grafana", "prometheus")
    * `message` - Optional. Detailed message
    * `labels` - Optional. Map of labels
    * `annotations` - Optional. Map of annotations
  """
  def create(conn, %{"alert" => alert_params}) do
    # Set fired_at if not provided
    alert_params = Map.put_new(alert_params, "fired_at", DateTime.utc_now())
    alert_params = Map.put_new(alert_params, "status", "firing")

    case Alerts.create_alert(alert_params) do
      {:ok, alert} ->
        conn
        |> put_status(:created)
        |> render(:show, alert: alert)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required 'alert' parameter"})
  end

  @doc """
  Acknowledges an alert.

  ## Request Body
    * `note` - Optional. Acknowledgement note
  """
  def acknowledge(conn, %{"id" => id} = params) do
    # Get current user from conn (set by auth plug)
    user = get_current_user(conn)

    case Alerts.get_alert(id) do
      {:ok, alert} ->
        case Alerts.acknowledge_alert(alert, user, params["note"]) do
          {:ok, updated_alert} ->
            render(conn, :show, alert: updated_alert)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Alert not found"})
    end
  end

  @doc """
  Resolves an alert.

  ## Request Body
    * `resolution_note` - Optional. Resolution note
  """
  def resolve(conn, %{"id" => id} = params) do
    user = get_current_user(conn)

    case Alerts.get_alert(id) do
      {:ok, alert} ->
        case Alerts.resolve_alert(alert, user, params["resolution_note"]) do
          {:ok, updated_alert} ->
            render(conn, :show, alert: updated_alert)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Alert not found"})
    end
  end

  # Private helpers

  defp parse_integer(nil, default), do: default
  defp parse_integer(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end
  defp parse_integer(val, _default) when is_integer(val) and val > 0, do: val
  defp parse_integer(_, default), do: default

  defp get_current_user(conn) do
    # Try to get user from conn assigns (set by auth middleware)
    # Fall back to a system user for API key auth
    conn.assigns[:current_user] || %{id: 0, name: "API"}
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
