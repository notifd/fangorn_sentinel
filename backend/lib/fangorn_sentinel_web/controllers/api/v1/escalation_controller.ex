defmodule FangornSentinelWeb.API.V1.EscalationController do
  @moduledoc """
  REST API controller for escalation policy management.
  """
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Escalation
  alias FangornSentinel.Escalation.{Policy, Step}

  action_fallback FangornSentinelWeb.FallbackController

  # Policy CRUD

  def index(conn, _params) do
    policies = Escalation.list_policies()
    json(conn, %{policies: Enum.map(policies, &policy_to_json/1)})
  end

  def show(conn, %{"id" => id}) do
    policy = Escalation.get_policy_with_steps!(id)
    json(conn, %{policy: policy_to_json(policy)})
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Escalation policy not found"})
  end

  def create(conn, %{"policy" => policy_params}) do
    case Escalation.create_policy(policy_params) do
      {:ok, policy} ->
        conn
        |> put_status(:created)
        |> json(%{policy: policy_to_json(policy)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "policy" => policy_params}) do
    policy = Escalation.get_policy!(id)

    case Escalation.update_policy(policy, policy_params) do
      {:ok, policy} ->
        json(conn, %{policy: policy_to_json(policy)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Escalation policy not found"})
  end

  def delete(conn, %{"id" => id}) do
    policy = Escalation.get_policy!(id)

    case Escalation.delete_policy(policy) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to delete policy"})
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Escalation policy not found"})
  end

  # Step management

  def create_step(conn, %{"policy_id" => policy_id, "step" => step_params}) do
    step_params = Map.put(step_params, "policy_id", policy_id)

    case Escalation.create_step(step_params) do
      {:ok, step} ->
        conn
        |> put_status(:created)
        |> json(%{step: step_to_json(step)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def list_steps(conn, %{"policy_id" => policy_id}) do
    policy = Escalation.get_policy_with_steps!(policy_id)
    json(conn, %{steps: Enum.map(policy.steps, &step_to_json/1)})
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Escalation policy not found"})
  end

  # Test escalation endpoint
  def test(conn, %{"policy_id" => policy_id}) do
    policy = Escalation.get_policy_with_steps!(policy_id)

    # Return a simulation of how the escalation would proceed
    simulation = simulate_escalation(policy)

    json(conn, %{
      policy_id: policy.id,
      policy_name: policy.name,
      simulation: simulation
    })
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Escalation policy not found"})
  end

  # Helpers

  defp simulate_escalation(policy) do
    Enum.map(policy.steps, fn step ->
      %{
        step_number: step.step_number,
        wait_minutes: step.wait_minutes,
        notify_users: step.notify_users,
        notify_schedules: step.notify_schedules,
        channels: step.channels,
        cumulative_wait_minutes: calculate_cumulative_wait(policy.steps, step.step_number)
      }
    end)
  end

  defp calculate_cumulative_wait(steps, up_to_step) do
    steps
    |> Enum.filter(&(&1.step_number < up_to_step))
    |> Enum.map(& &1.wait_minutes)
    |> Enum.sum()
  end

  defp policy_to_json(%Policy{} = policy) do
    base = %{
      id: policy.id,
      name: policy.name,
      description: policy.description,
      team_id: policy.team_id,
      inserted_at: policy.inserted_at,
      updated_at: policy.updated_at
    }

    case policy.steps do
      %Ecto.Association.NotLoaded{} -> base
      steps when is_list(steps) -> Map.put(base, :steps, Enum.map(steps, &step_to_json/1))
    end
  end

  defp step_to_json(%Step{} = step) do
    %{
      id: step.id,
      step_number: step.step_number,
      wait_minutes: step.wait_minutes,
      notify_users: step.notify_users,
      notify_schedules: step.notify_schedules,
      channels: step.channels,
      inserted_at: step.inserted_at,
      updated_at: step.updated_at
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
