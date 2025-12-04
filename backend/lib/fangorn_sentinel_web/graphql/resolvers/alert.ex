defmodule FangornSentinelWeb.GraphQL.Resolvers.Alert do
  alias FangornSentinel.Alerts

  def list_alerts(_parent, args, %{context: %{current_user: user}}) do
    # Filter alerts visible to the user
    filters = Map.merge(args, %{user_id: user.id})
    {:ok, Alerts.list_alerts(filters)}
  end

  def list_alerts(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def get_alert(_parent, %{id: id}, %{context: %{current_user: user}}) do
    case Alerts.get_alert(id) do
      nil ->
        {:error, "Alert not found"}

      alert ->
        # Check if user has access to this alert
        if alert.assigned_to_id == user.id do
          {:ok, alert}
        else
          {:error, "Access denied"}
        end
    end
  end

  def get_alert(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def acknowledge(_parent, %{alert_id: alert_id} = args, %{context: %{current_user: user}}) do
    with {:ok, alert} <- Alerts.get_alert(alert_id),
         {:ok, updated_alert} <- Alerts.acknowledge_alert(alert, user, args[:note]) do
      # Publish to subscriptions
      Absinthe.Subscription.publish(
        FangornSentinelWeb.Endpoint,
        updated_alert,
        acknowledge_alert: "alert:#{alert_id}"
      )

      {:ok, updated_alert}
    else
      {:error, :not_found} -> {:error, "Alert not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  def acknowledge(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def resolve(_parent, %{alert_id: alert_id} = args, %{context: %{current_user: user}}) do
    with {:ok, alert} <- Alerts.get_alert(alert_id),
         {:ok, updated_alert} <- Alerts.resolve_alert(alert, user, args[:resolution_note]) do
      # Publish to subscriptions
      Absinthe.Subscription.publish(
        FangornSentinelWeb.Endpoint,
        updated_alert,
        resolve_alert: "alert:#{alert_id}"
      )

      {:ok, updated_alert}
    else
      {:error, :not_found} -> {:error, "Alert not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  def resolve(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end
end
