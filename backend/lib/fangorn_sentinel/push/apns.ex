defmodule FangornSentinel.Push.APNS do
  @moduledoc """
  Apple Push Notification Service (APNs) implementation.

  Sends critical alert notifications to iOS devices using Pigeon.
  """

  @doc """
  Sends a critical alert notification to an iOS device.

  ## Parameters
    - alert: The alert struct containing alert details
    - user: The user receiving the notification
    - device: The push device struct with the APNs token

  ## Returns
    - `:ok` on successful send
    - `{:error, reason}` on failure
  """
  def send_alert_notification(alert, user, device) do
    notification = build_notification(alert, user, device.device_token)

    # Send via configured APNs connection
    # If APNs is not configured (no env vars), this will return :ok without sending
    case Application.get_env(:pigeon, :apns) do
      nil ->
        # APNs not configured, log and return ok (for development)
        require Logger
        Logger.warning("APNs not configured - skipping push notification")
        :ok

      _ ->
        # APNs configured, send notification
        case Pigeon.APNS.push(notification, :fangorn_apns) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
          _ -> :ok
        end
    end
  end

  defp build_notification(alert, _user, device_token) do
    Pigeon.APNS.Notification.new(
      %{
        "aps" => %{
          "alert" => %{
            "title" => alert.title,
            "body" => alert.message || "New alert received",
            "sound" => "critical.caf"
          },
          "badge" => 1,
          "content-available" => 1,
          "interruption-level" => "critical"
        },
        "alert_id" => alert.id,
        "severity" => to_string(alert.severity),
        "source" => alert.source
      },
      device_token,
      "com.notifd.fangornsentinel"
    )
  end
end
