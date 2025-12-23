defmodule FangornSentinel.Escalation do
  @moduledoc """
  The Escalation context - manages escalation policies and steps.
  """

  import Ecto.Query, warn: false
  alias FangornSentinel.Repo
  alias FangornSentinel.Escalation.{History, Policy, Step}

  @doc """
  Returns the list of escalation policies.
  """
  def list_policies do
    Repo.all(Policy)
  end

  @doc """
  Gets a single policy.
  """
  def get_policy!(id), do: Repo.get!(Policy, id)

  @doc """
  Gets a policy with its steps preloaded and ordered.
  """
  def get_policy_with_steps!(id) do
    Policy
    |> Repo.get!(id)
    |> Repo.preload(steps: from(s in Step, order_by: s.step_number))
  end

  @doc """
  Creates a policy.
  """
  def create_policy(attrs \\ %{}) do
    %Policy{}
    |> Policy.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a policy.
  """
  def update_policy(%Policy{} = policy, attrs) do
    policy
    |> Policy.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a policy.
  """
  def delete_policy(%Policy{} = policy) do
    Repo.delete(policy)
  end

  @doc """
  Creates a step for a policy.
  """
  def create_step(attrs \\ %{}) do
    %Step{}
    |> Step.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets the escalation policy for an alert based on its team.
  Returns the first policy found for the team, or nil.
  """
  def get_policy_for_alert(alert) do
    case alert.team_id do
      nil ->
        # No team assigned, get default policy
        Policy
        |> where([p], is_nil(p.team_id))
        |> limit(1)
        |> Repo.one()
        |> maybe_preload_steps()

      team_id ->
        Policy
        |> where([p], p.team_id == ^team_id)
        |> limit(1)
        |> Repo.one()
        |> maybe_preload_steps()
    end
  end

  defp maybe_preload_steps(nil), do: nil
  defp maybe_preload_steps(policy) do
    Repo.preload(policy, steps: from(s in Step, order_by: s.step_number))
  end

  @doc """
  Gets the next step in an escalation policy.
  """
  def get_next_step(%Policy{} = policy, current_step_number) do
    Step
    |> where([s], s.policy_id == ^policy.id)
    |> where([s], s.step_number > ^current_step_number)
    |> order_by([s], asc: s.step_number)
    |> limit(1)
    |> Repo.one()
  end

  # History functions

  @doc """
  Records an escalation history entry.
  """
  def record_history(attrs) do
    %History{}
    |> History.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Records that escalation has started for an alert.
  """
  def record_escalation_started(alert_id, policy_id) do
    record_history(%{
      alert_id: alert_id,
      policy_id: policy_id,
      step_number: 0,
      action: "escalation_started",
      metadata: %{started_at: DateTime.utc_now()}
    })
  end

  @doc """
  Records that an escalation step was executed.
  """
  def record_step_executed(alert_id, policy_id, step_number, user_ids, channels) do
    record_history(%{
      alert_id: alert_id,
      policy_id: policy_id,
      step_number: step_number,
      action: "step_executed",
      notified_user_ids: user_ids,
      channels_used: channels
    })
  end

  @doc """
  Records that escalation was cancelled (alert acknowledged/resolved).
  """
  def record_escalation_cancelled(alert_id, policy_id, step_number, reason) do
    record_history(%{
      alert_id: alert_id,
      policy_id: policy_id,
      step_number: step_number,
      action: "escalation_cancelled",
      metadata: %{reason: to_string(reason), cancelled_at: DateTime.utc_now()}
    })
  end

  @doc """
  Records that escalation completed (all steps executed).
  """
  def record_escalation_completed(alert_id, policy_id, final_step) do
    record_history(%{
      alert_id: alert_id,
      policy_id: policy_id,
      step_number: final_step,
      action: "escalation_completed",
      metadata: %{completed_at: DateTime.utc_now()}
    })
  end

  @doc """
  Gets escalation history for an alert.
  """
  def get_history_for_alert(alert_id) do
    History
    |> where([h], h.alert_id == ^alert_id)
    |> order_by([h], asc: h.inserted_at)
    |> Repo.all()
  end
end
