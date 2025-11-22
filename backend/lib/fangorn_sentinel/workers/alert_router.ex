defmodule FangornSentinel.Workers.AlertRouter do
  @moduledoc """
  Oban worker that routes alerts to on-call users.

  This worker is responsible for:
  - Assigning alerts to the appropriate on-call user
  - Only routing alerts that are in "firing" status
  - Skipping alerts that are already assigned, acknowledged, or resolved
  """

  use Oban.Worker,
    queue: :alerts,
    max_attempts: 3

  alias FangornSentinel.Alerts

  @doc """
  Performs the alert routing job.

  ## Job Args
    * `alert_id` - Required. The ID of the alert to route
    * `on_call_user_id` - Required. The ID of the on-call user to assign the alert to

  ## Returns
    * `:ok` - Job completed successfully
    * `{:error, :alert_not_found}` - Alert doesn't exist
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"alert_id" => alert_id, "on_call_user_id" => on_call_user_id}}) do
    case Alerts.get_alert(alert_id) do
      {:ok, alert} ->
        route_alert(alert, on_call_user_id)

      {:error, :not_found} ->
        {:error, :alert_not_found}
    end
  end

  @doc """
  Enqueues an alert routing job.

  ## Examples

      iex> enqueue_for_alert(alert_id, user_id)
      {:ok, %Oban.Job{}}

      iex> enqueue_for_alert(alert_id, user_id, schedule_in: 60)
      {:ok, %Oban.Job{}}
  """
  def enqueue_for_alert(alert_id, on_call_user_id, opts \\ []) do
    %{alert_id: alert_id, on_call_user_id: on_call_user_id}
    |> new(opts)
    |> Oban.insert()
  end

  # Private functions

  defp route_alert(alert, on_call_user_id) do
    cond do
      # Don't route if alert is already assigned
      alert.assigned_to_id != nil ->
        :ok

      # Don't route if alert is not in firing status
      alert.status != "firing" ->
        :ok

      # Route the alert
      true ->
        assign_alert(alert, on_call_user_id)
    end
  end

  defp assign_alert(alert, on_call_user_id) do
    case Alerts.update_alert(alert, %{assigned_to_id: on_call_user_id}) do
      {:ok, updated_alert} ->
        # Enqueue notification job
        FangornSentinel.Workers.Notifier.enqueue_for_alert(updated_alert.id, on_call_user_id)
        :ok

      {:error, _changeset} ->
        {:error, :assignment_failed}
    end
  end
end
