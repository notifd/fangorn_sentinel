defmodule FangornSentinel.Workers.Notifier do
  @moduledoc """
  Oban worker that sends push notifications to users' devices.

  This worker is responsible for:
  - Finding all enabled devices for a user
  - Sending push notifications to iOS devices (APNs)
  - Sending push notifications to Android devices (FCM)
  - Handling notification delivery failures
  """

  use Oban.Worker,
    queue: :notifications,
    max_attempts: 3

  alias FangornSentinel.Alerts
  alias FangornSentinel.Repo
  alias FangornSentinel.Push.PushDevice
  alias FangornSentinel.Accounts.User
  import Ecto.Query

  @doc """
  Performs the notification job.

  ## Job Args
    * `alert_id` - Required. The ID of the alert to notify about
    * `user_id` - Required. The ID of the user to notify

  ## Returns
    * `:ok` - Job completed successfully
    * `{:error, :alert_not_found}` - Alert doesn't exist
    * `{:error, :user_not_found}` - User doesn't exist
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"alert_id" => alert_id, "user_id" => user_id}}) do
    with {:ok, alert} <- get_alert(alert_id),
         {:ok, user} <- get_user(user_id),
         devices <- get_enabled_devices(user_id) do
      send_notifications(alert, user, devices)
      :ok
    end
  end

  @doc """
  Enqueues a notification job.

  ## Examples

      iex> enqueue_for_alert(alert_id, user_id)
      {:ok, %Oban.Job{}}

      iex> enqueue_for_alert(alert_id, user_id, schedule_in: 60)
      {:ok, %Oban.Job{}}
  """
  def enqueue_for_alert(alert_id, user_id, opts \\ []) do
    %{alert_id: alert_id, user_id: user_id}
    |> new(opts)
    |> Oban.insert()
  end

  # Private functions

  defp get_alert(alert_id) do
    case Alerts.get_alert(alert_id) do
      {:ok, alert} -> {:ok, alert}
      {:error, :not_found} -> {:error, :alert_not_found}
    end
  end

  defp get_user(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp get_enabled_devices(user_id) do
    from(d in PushDevice,
      where: d.user_id == ^user_id and d.enabled == true
    )
    |> Repo.all()
  end

  defp send_notifications(_alert, _user, []) do
    # No devices to send to
    :ok
  end

  defp send_notifications(alert, user, devices) do
    Enum.each(devices, fn device ->
      send_push_notification(alert, user, device)
    end)
  end

  defp send_push_notification(alert, user, device) do
    case device.platform do
      "ios" ->
        send_apns_notification(alert, user, device)

      "android" ->
        send_fcm_notification(alert, user, device)

      _ ->
        :ok
    end
  end

  defp send_apns_notification(alert, user, device) do
    FangornSentinel.Push.APNS.send_alert_notification(alert, user, device)
  end

  defp send_fcm_notification(alert, user, device) do
    FangornSentinel.Push.FCM.send_alert_notification(alert, user, device)
  end
end
