defmodule FangornSentinel.Push.APNS do
  @moduledoc """
  Apple Push Notification Service (APNs) implementation.

  Sends critical alert notifications to iOS devices using Pigeon 2.x.
  """

  require Logger

  alias FangornSentinel.Push.APNSDispatcher

  @doc """
  Checks if APNs is configured and available.
  """
  def configured? do
    Application.get_env(:fangorn_sentinel, APNSDispatcher) != nil
  end

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
  def send_alert_notification(alert, _user, device) do
    if configured?() do
      notification = build_notification(alert, device.device_token)
      do_push(notification)
    else
      Logger.warning("APNs not configured - skipping push notification to #{device.device_token}")
      :ok
    end
  end

  defp do_push(notification) do
    case APNSDispatcher.push(notification) do
      %{response: :success} ->
        Logger.debug("APNs push successful")
        :ok

      %{response: response} when response in [:bad_device_token, :unregistered] ->
        Logger.warning("APNs device token invalid: #{inspect(response)}")
        # Could trigger device cleanup here
        {:error, {:invalid_token, response}}

      %{response: response} = notification ->
        Logger.error("APNs push failed: #{inspect(response)}, notification: #{inspect(notification)}")
        {:error, response}
    end
  rescue
    e ->
      Logger.error("APNs push exception: #{inspect(e)}")
      {:error, :push_exception}
  end

  defp build_notification(alert, device_token) do
    # Get bundle ID from config or use default
    bundle_id = Application.get_env(:fangorn_sentinel, :apns_bundle_id, "com.notifd.fangornsentinel")

    # Build the APS payload
    aps = %{
      "alert" => %{
        "title" => truncate(alert.title, 100),
        "body" => truncate(alert.message || "New alert received", 500)
      },
      "sound" => %{
        "critical" => 1,
        "name" => "critical.caf",
        "volume" => 1.0
      },
      "badge" => 1,
      "content-available" => 1,
      "interruption-level" => "critical",
      "relevance-score" => 1.0
    }

    # Custom data
    custom_data = %{
      "alert_id" => to_string(alert.id),
      "severity" => to_string(alert.severity),
      "source" => alert.source,
      "action" => "view_alert"
    }

    # Merge APS with custom data
    payload = Map.merge(%{"aps" => aps}, custom_data)

    Pigeon.APNS.Notification.new(device_token, payload, bundle_id)
  end

  defp truncate(nil, _max), do: nil
  defp truncate(str, max) when byte_size(str) <= max, do: str
  defp truncate(str, max), do: String.slice(str, 0, max - 3) <> "..."
end
