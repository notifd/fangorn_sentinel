defmodule FangornSentinel.Workers.Escalator do
  @moduledoc """
  Oban worker that processes escalation steps with timing.

  This worker is responsible for:
  - Processing escalation steps in sequence
  - Waiting the configured time between steps
  - Notifying users/schedules at each step
  - Stopping escalation when alert is acknowledged/resolved
  - Scheduling the next step after wait time
  """

  use Oban.Worker,
    queue: :escalations,
    max_attempts: 5

  require Logger

  alias FangornSentinel.{Alerts, Escalation, Schedules}
  alias FangornSentinel.Workers.Notifier

  @doc """
  Performs the escalation job.

  ## Job Args
    * `alert_id` - Required. The ID of the alert being escalated
    * `policy_id` - Required. The ID of the escalation policy
    * `step_number` - Required. The current step number (1-indexed)

  ## Returns
    * `:ok` - Step completed, next step scheduled (or escalation complete)
    * `{:cancel, reason}` - Escalation cancelled (alert acknowledged/resolved)
    * `{:error, reason}` - Error occurred
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"alert_id" => alert_id, "policy_id" => policy_id, "step_number" => step_number}}) do
    with {:ok, alert} <- get_alert(alert_id),
         :firing <- check_alert_status(alert),
         {:ok, policy} <- get_policy(policy_id),
         {:ok, step} <- get_step(policy, step_number) do

      Logger.info("Escalating alert #{alert_id} - policy #{policy_id} step #{step_number}")

      # Notify all targets in this step and record history
      user_ids = notify_step(alert, step)
      channels = Enum.map(step.channels || [], &to_string/1)
      Escalation.record_step_executed(alert_id, policy_id, step_number, user_ids, channels)

      # Schedule next step if there is one
      schedule_next_step(alert_id, policy, step_number)

      :ok
    else
      {:cancel, reason} = cancel ->
        Logger.info("Escalation cancelled for alert #{alert_id}: #{reason}")
        Escalation.record_escalation_cancelled(alert_id, policy_id, step_number, reason)
        cancel

      {:error, reason} = error ->
        Logger.error("Escalation error for alert #{alert_id}: #{inspect(reason)}")
        error
    end
  end

  def perform(%Oban.Job{args: args}) do
    Logger.error("Invalid escalator job args: #{inspect(args)}")
    {:error, :invalid_args}
  end

  @doc """
  Starts escalation for an alert using its team's policy.
  """
  def start_escalation(alert) do
    case Escalation.get_policy_for_alert(alert) do
      nil ->
        Logger.warning("No escalation policy found for alert #{alert.id}")
        {:error, :no_policy}

      policy ->
        # Record that escalation started
        Escalation.record_escalation_started(alert.id, policy.id)
        enqueue_step(alert.id, policy.id, 1)
    end
  end

  @doc """
  Enqueues an escalation step job.
  """
  def enqueue_step(alert_id, policy_id, step_number, opts \\ []) do
    %{alert_id: alert_id, policy_id: policy_id, step_number: step_number}
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

  defp check_alert_status(%{status: :firing}), do: :firing
  defp check_alert_status(%{status: :acknowledged}), do: {:cancel, :acknowledged}
  defp check_alert_status(%{status: :resolved}), do: {:cancel, :resolved}
  defp check_alert_status(_), do: {:cancel, :unknown_status}

  defp get_policy(policy_id) do
    try do
      {:ok, Escalation.get_policy_with_steps!(policy_id)}
    rescue
      Ecto.NoResultsError -> {:error, :policy_not_found}
    end
  end

  defp get_step(policy, step_number) do
    case Enum.find(policy.steps, &(&1.step_number == step_number)) do
      nil -> {:error, :step_not_found}
      step -> {:ok, step}
    end
  end

  defp notify_step(alert, step) do
    # Collect all user IDs to notify
    user_ids = collect_notification_targets(step)

    # Enqueue notification jobs for each user
    Enum.each(user_ids, fn user_id ->
      Notifier.enqueue_for_alert(alert.id, user_id)
    end)

    Logger.info("Escalation step #{step.step_number}: notifying #{length(user_ids)} users via #{inspect(step.channels)}")

    # Return user_ids for history tracking
    user_ids
  end

  defp collect_notification_targets(step) do
    direct_users = step.notify_users || []

    schedule_users =
      (step.notify_schedules || [])
      |> Enum.flat_map(&get_on_call_users/1)

    (direct_users ++ schedule_users)
    |> Enum.uniq()
  end

  defp get_on_call_users(schedule_id) do
    try do
      Schedules.who_is_on_call_with_overrides(schedule_id)
    rescue
      _ -> []
    end
  end

  defp schedule_next_step(alert_id, policy, current_step_number) do
    next_step = Escalation.get_next_step(policy, current_step_number)

    case next_step do
      nil ->
        Logger.info("Escalation complete for alert #{alert_id} - no more steps")
        Escalation.record_escalation_completed(alert_id, policy.id, current_step_number)
        :ok

      step ->
        # Get wait time from current step
        current_step = Enum.find(policy.steps, &(&1.step_number == current_step_number))
        wait_seconds = (current_step.wait_minutes || 5) * 60

        Logger.info("Scheduling escalation step #{step.step_number} for alert #{alert_id} in #{wait_seconds} seconds")

        enqueue_step(alert_id, policy.id, step.step_number, schedule_in: wait_seconds)
    end
  end
end
