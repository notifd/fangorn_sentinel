defmodule FangornSentinelWeb.API.V1.AlertJSON do
  @moduledoc """
  JSON rendering for alerts REST API.
  """

  alias FangornSentinel.Alerts.Alert

  @doc """
  Renders a list of alerts.
  """
  def index(%{alerts: alerts}) do
    %{
      data: Enum.map(alerts, &alert_to_json/1),
      meta: %{
        count: length(alerts)
      }
    }
  end

  @doc """
  Renders a single alert.
  """
  def show(%{alert: alert}) do
    %{data: alert_to_json(alert)}
  end

  defp alert_to_json(%Alert{} = alert) do
    %{
      id: alert.id,
      title: alert.title,
      message: alert.message,
      severity: alert.severity,
      status: alert.status,
      source: alert.source,
      source_id: alert.source_id,
      labels: alert.labels,
      annotations: alert.annotations,
      fired_at: alert.fired_at,
      acknowledged_at: alert.acknowledged_at,
      acknowledged_by_id: alert.acknowledged_by_id,
      resolved_at: alert.resolved_at,
      resolved_by_id: alert.resolved_by_id,
      assigned_to_id: alert.assigned_to_id,
      inserted_at: alert.inserted_at,
      updated_at: alert.updated_at
    }
  end
end
