defmodule FangornSentinelWeb.API.V1.WebhookController do
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Alerts

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
    # Limit alerts to prevent DoS - max 100 alerts per webhook
    cond do
      length(alerts) > 100 ->
        {:error, :too_many_alerts}

      # Check for huge payloads before processing
      has_huge_fields?(alerts) ->
        {:error, :payload_too_large}

      true ->
        alert_data_list = Enum.map(alerts, &parse_grafana_alert/1)
        {:ok, alert_data_list}
    end
  end

  defp parse_grafana_webhook(_), do: {:error, :invalid_payload}

  # Check if any field in alerts is excessively large (> 1MB)
  defp has_huge_fields?(alerts) do
    Enum.any?(alerts, fn alert ->
      check_map_size(alert) > 1_000_000
    end)
  end

  defp check_map_size(value) when is_map(value) do
    Enum.reduce(value, 0, fn {k, v}, acc ->
      acc + check_map_size(k) + check_map_size(v)
    end)
  end

  defp check_map_size(value) when is_binary(value), do: byte_size(value)

  defp check_map_size(value) when is_list(value) do
    Enum.reduce(value, 0, fn item, acc -> acc + check_map_size(item) end)
  end

  defp check_map_size(_), do: 0

  defp parse_grafana_alert(alert) do
    # Ensure labels and annotations are maps, not other types
    labels = ensure_map(Map.get(alert, "labels", %{}))
    annotations = ensure_map(Map.get(alert, "annotations", %{}))

    %{
      title: sanitize_string(Map.get(labels, "alertname", "Unknown Alert")),
      message: sanitize_string(get_alert_message(annotations)),
      severity: map_severity(Map.get(labels, "severity", "info")),
      source: "grafana",
      source_id: sanitize_string(Map.get(alert, "fingerprint")),
      labels: sanitize_map(labels),
      annotations: sanitize_map(annotations),
      fired_at: parse_timestamp(Map.get(alert, "startsAt"))
    }
  end

  # Ensure value is a map, convert to empty map if not
  defp ensure_map(value) when is_map(value), do: value
  defp ensure_map(_), do: %{}

  # Recursively sanitize all strings in a map (remove null bytes and control chars)
  defp sanitize_map(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      {sanitize_value(k), sanitize_value(v)}
    end)
  end

  defp sanitize_value(value) when is_binary(value), do: sanitize_string(value)
  defp sanitize_value(value) when is_map(value), do: sanitize_map(value)
  defp sanitize_value(value), do: value

  # Remove null bytes and control characters from strings (PostgreSQL UTF8 doesn't allow them)
  # Also truncate to prevent DoS via huge strings
  defp sanitize_string(nil), do: nil

  defp sanitize_string(value) when is_binary(value) do
    value
    # Truncate to 10KB max
    |> String.slice(0, 10_000)
    # Remove null bytes
    |> String.replace(<<0>>, "")
    # Remove control characters
    |> String.replace(~r/[\x00-\x1F\x7F]/, "")
  end

  defp sanitize_string(_), do: nil

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
      {:ok, datetime, _offset} ->
        # Validate timestamp is reasonable (within past 7 days or future 1 hour)
        validate_timestamp_range(datetime)

      _ ->
        DateTime.utc_now()
    end
  end

  defp validate_timestamp_range(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(datetime, now)

    cond do
      # More than 7 days in the past - use current time
      diff_seconds < -7 * 24 * 60 * 60 ->
        DateTime.utc_now()

      # More than 1 hour in the future - use current time
      diff_seconds > 60 * 60 ->
        DateTime.utc_now()

      # Within reasonable range
      true ->
        datetime
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

  defp enqueue_routing_job(_alert) do
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
