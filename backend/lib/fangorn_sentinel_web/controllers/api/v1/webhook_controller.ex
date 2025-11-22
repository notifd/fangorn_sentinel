defmodule FangornSentinelWeb.API.V1.WebhookController do
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Alerts
  alias FangornSentinel.Workers.AlertRouter

  @doc """
  Handles incoming webhooks from Grafana AlertManager.

  Expected payload format:
  ```json
  {
    "receiver": "fangorn-sentinel",
    "status": "firing",
    "alerts": [
      {
        "status": "firing",
        "labels": {
          "alertname": "HighCPU",
          "severity": "critical"
        },
        "annotations": {
          "summary": "CPU usage high",
          "description": "..."
        },
        "startsAt": "2025-11-22T00:00:00Z",
        "fingerprint": "abc123"
      }
    ]
  }
  ```
  """
  def grafana(conn, params) do
    case parse_grafana_webhook(params) do
      {:ok, alert_data_list} ->
        created_count =
          Enum.reduce(alert_data_list, 0, fn alert_data, acc ->
            case create_or_update_alert(alert_data) do
              {:ok, _alert} -> acc + 1
              {:error, _} -> acc
            end
          end)

        conn
        |> put_status(:ok)
        |> json(%{status: "ok", received: created_count})

      {:error, _reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid webhook payload"})
    end
  end

  # Private functions

  defp parse_grafana_webhook(%{"alerts" => alerts}) when is_list(alerts) do
    alert_data_list = Enum.map(alerts, &parse_grafana_alert/1)
    {:ok, alert_data_list}
  end

  defp parse_grafana_webhook(_), do: {:error, :invalid_payload}

  defp parse_grafana_alert(alert) do
    labels = Map.get(alert, "labels", %{})
    annotations = Map.get(alert, "annotations", %{})

    %{
      title: Map.get(labels, "alertname", "Unknown Alert"),
      message: get_alert_message(annotations),
      severity: map_severity(Map.get(labels, "severity", "info")),
      source: "grafana",
      source_id: Map.get(alert, "fingerprint"),
      labels: labels,
      annotations: annotations,
      fired_at: parse_timestamp(Map.get(alert, "startsAt"))
    }
  end

  defp get_alert_message(annotations) do
    Map.get(annotations, "summary") || Map.get(annotations, "description")
  end

  defp map_severity("critical"), do: "critical"
  defp map_severity("warning"), do: "warning"
  defp map_severity("page"), do: "critical"
  defp map_severity("info"), do: "info"
  defp map_severity(_), do: "info"

  defp parse_timestamp(nil), do: DateTime.utc_now()
  defp parse_timestamp("0001-01-01T00:00:00Z"), do: DateTime.utc_now()

  defp parse_timestamp(timestamp_string) do
    case DateTime.from_iso8601(timestamp_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  defp create_or_update_alert(alert_data) do
    # Check if alert with this fingerprint already exists
    case find_alert_by_fingerprint(alert_data.source_id) do
      nil ->
        # Create new alert
        case Alerts.create_alert(alert_data) do
          {:ok, alert} = result ->
            # Enqueue routing job for new alerts
            # TODO: Replace hardcoded user_id with actual on-call lookup
            enqueue_routing_job(alert)
            result

          error ->
            error
        end

      existing_alert ->
        # Update existing alert (don't re-route)
        Alerts.update_alert(existing_alert, alert_data)
    end
  end

  defp enqueue_routing_job(alert) do
    # TODO: Implement actual on-call schedule lookup
    # For now, we'll skip enqueueing if no on-call user is available
    # This will be replaced with Schedule.who_is_on_call?() in Phase 2
    :ok
  end

  defp find_alert_by_fingerprint(nil), do: nil

  defp find_alert_by_fingerprint(fingerprint) do
    # Find by source and source_id
    alerts = Alerts.list_alerts()

    Enum.find(alerts, fn alert ->
      alert.source == "grafana" && alert.source_id == fingerprint
    end)
  end
end
