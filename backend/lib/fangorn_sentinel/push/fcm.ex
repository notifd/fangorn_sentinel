defmodule FangornSentinel.Push.FCM do
  @moduledoc """
  Firebase Cloud Messaging (FCM) implementation.

  Sends high-priority notifications to Android devices using Pigeon.
  """

  @doc """
  Sends a high-priority notification to an Android device.

  ## Parameters
    - alert: The alert struct containing alert details
    - user: The user receiving the notification
    - device: The push device struct with the FCM token

  ## Returns
    - `:ok` on successful send
    - `{:error, reason}` on failure
  """
  def send_alert_notification(alert, user, device) do
    notification = build_notification(alert, user, device.device_token)

    # Send via configured FCM connection
    # If FCM is not configured (no env vars), this will return :ok without sending
    case Application.get_env(:pigeon, :fcm_v1) do
      nil ->
        # FCM not configured, log and return ok (for development)
        require Logger
        Logger.warning("FCM not configured - skipping push notification")
        :ok

      _ ->
        # FCM configured, send notification
        case Pigeon.FCM.push(notification, :fangorn_fcm) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
          _ -> :ok
        end
    end
  end

  defp build_notification(alert, _user, device_token) do
    Pigeon.FCM.Notification.new(
      {:token, device_token},
      %{
        "notification" => %{
          "title" => alert.title,
          "body" => alert.message || "New alert received"
        },
        "android" => %{
          "priority" => "high",
          "notification" => %{
            "channel_id" => "critical_alerts",
            "sound" => "critical_alert.mp3",
            "priority" => "max"
          }
        },
        "data" => %{
          "alert_id" => to_string(alert.id),
          "severity" => to_string(alert.severity),
          "source" => alert.source,
          "action" => "view_alert"
        }
      },
      nil
    )
  end
end
