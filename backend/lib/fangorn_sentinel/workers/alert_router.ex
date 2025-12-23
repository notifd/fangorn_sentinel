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
  alias FangornSentinel.Workers.Escalator

  require Logger

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
  def perform(%Oban.Job{args: %{"alert_id" => alert_id, "on_call_user_id" => on_call_user_id}})
      when is_integer(alert_id) and alert_id > 0 and is_integer(on_call_user_id) and on_call_user_id > 0 do
    case Alerts.get_alert(alert_id) do
      {:ok, alert} ->
        route_alert(alert, on_call_user_id)

      {:error, :not_found} ->
        {:error, :alert_not_found}
    end
  end

  # Handle missing or invalid args gracefully
  def perform(%Oban.Job{args: args}) do
    cond do
      not Map.has_key?(args, "alert_id") ->
        {:error, :missing_alert_id}

      not Map.has_key?(args, "on_call_user_id") ->
        {:error, :missing_on_call_user_id}

      not is_integer(args["alert_id"]) or args["alert_id"] <= 0 ->
        {:error, :invalid_alert_id}

      not is_integer(args["on_call_user_id"]) or args["on_call_user_id"] <= 0 ->
        {:error, :invalid_on_call_user_id}

      true ->
        {:error, :invalid_args}
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
        # Enqueue immediate notification job
        FangornSentinel.Workers.Notifier.enqueue_for_alert(updated_alert.id, on_call_user_id)

        # Start escalation workflow
        start_escalation_for_alert(updated_alert)

        :ok

      {:error, changeset} ->
        # Handle FK constraint violations
        if has_constraint_error?(changeset, :assigned_to_id) do
          {:error, :user_not_found}
        else
          {:error, :assignment_failed}
        end
    end
  rescue
    # Catch constraint exceptions that bubble up
    Ecto.ConstraintError ->
      {:error, :user_not_found}
  end

  defp start_escalation_for_alert(alert) do
    case Escalator.start_escalation(alert) do
      {:ok, _job} ->
        Logger.info("Started escalation for alert #{alert.id}")
        :ok

      {:error, :no_policy} ->
        Logger.debug("No escalation policy for alert #{alert.id}")
        :ok

      {:error, reason} ->
        Logger.warning("Failed to start escalation for alert #{alert.id}: #{inspect(reason)}")
        :ok
    end
  end

  defp has_constraint_error?(changeset, field) do
    Enum.any?(changeset.errors, fn
      {^field, {_msg, opts}} -> Keyword.get(opts, :constraint) != nil
      _ -> false
    end)
  end
end
