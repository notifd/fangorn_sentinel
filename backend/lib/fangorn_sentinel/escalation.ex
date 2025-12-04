defmodule FangornSentinel.Escalation do
  @moduledoc """
  The Escalation context - manages escalation policies and steps.
  """

  import Ecto.Query, warn: false
  alias FangornSentinel.Repo
  alias FangornSentinel.Escalation.{Policy, Step}

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
end
