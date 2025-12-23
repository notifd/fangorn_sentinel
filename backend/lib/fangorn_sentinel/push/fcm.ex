defmodule FangornSentinel.Push.FCM do
  @moduledoc """
  Firebase Cloud Messaging (FCM) implementation.

  Sends high-priority notifications to Android devices using Pigeon 2.x.
  """

  require Logger

  alias FangornSentinel.Push.FCMDispatcher

  @doc """
  Checks if FCM is configured and available.
  """
  def configured? do
    Application.get_env(:fangorn_sentinel, FCMDispatcher) != nil
  end

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
  def send_alert_notification(alert, _user, device) do
    if configured?() do
      notification = build_notification(alert, device.device_token)
      do_push(notification)
    else
      Logger.warning("FCM not configured - skipping push notification to #{device.device_token}")
      :ok
    end
  end

  defp do_push(notification) do
    case FCMDispatcher.push(notification) do
      %{response: :success} ->
        Logger.debug("FCM push successful")
        :ok

      %{response: :unregistered} ->
        Logger.warning("FCM device token unregistered")
        # Could trigger device cleanup here
        {:error, {:invalid_token, :unregistered}}

      %{response: :invalid_argument, error: error} ->
        Logger.warning("FCM invalid argument: #{inspect(error)}")
        {:error, {:invalid_token, :invalid_argument}}

      %{response: response, error: error} ->
        Logger.error("FCM push failed: #{inspect(response)}, error: #{inspect(error)}")
        {:error, response}

      %{response: response} ->
        Logger.error("FCM push failed: #{inspect(response)}")
        {:error, response}
    end
  rescue
    e ->
      Logger.error("FCM push exception: #{inspect(e)}")
      {:error, :push_exception}
  end

  defp build_notification(alert, device_token) do
    # Build the message payload for FCM v1 API
    message = %{
      "notification" => %{
        "title" => truncate(alert.title, 100),
        "body" => truncate(alert.message || "New alert received", 500)
      },
      "android" => %{
        "priority" => "high",
        "ttl" => "86400s",
        "notification" => %{
          "channel_id" => "critical_alerts",
          "sound" => "critical_alert",
          "default_sound" => false,
          "default_vibrate_timings" => false,
          "vibrate_timings" => ["0.5s", "0.2s", "0.5s"],
          "notification_priority" => "PRIORITY_MAX",
          "visibility" => "PUBLIC"
        }
      },
      "data" => %{
        "alert_id" => to_string(alert.id),
        "severity" => to_string(alert.severity),
        "source" => alert.source || "unknown",
        "action" => "view_alert",
        "timestamp" => DateTime.to_iso8601(DateTime.utc_now())
      }
    }

    Pigeon.FCM.Notification.new({:token, device_token}, message)
  end

  defp truncate(nil, _max), do: nil
  defp truncate(str, max) when byte_size(str) <= max, do: str
  defp truncate(str, max), do: String.slice(str, 0, max - 3) <> "..."
end
