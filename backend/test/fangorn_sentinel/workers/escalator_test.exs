defmodule FangornSentinel.Workers.EscalatorTest do
  @moduledoc """
  Tests for Escalator Oban worker.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase
  use Oban.Testing, repo: FangornSentinel.Repo

  alias FangornSentinel.Workers.Escalator
  alias FangornSentinel.Escalation.{Policy, Step}

  describe "perform/1" do
    test "returns error for invalid args" do
      assert {:error, :invalid_args} = Escalator.perform(%Oban.Job{args: %{}})
    end

    test "returns error for missing alert_id" do
      args = %{"policy_id" => 1, "step_number" => 1}
      assert {:error, :invalid_args} = Escalator.perform(%Oban.Job{args: args})
    end

    test "returns error when alert not found" do
      args = %{"alert_id" => 999999, "policy_id" => 1, "step_number" => 1}
      assert {:error, :alert_not_found} = Escalator.perform(%Oban.Job{args: args})
    end
  end

  describe "enqueue_step/4" do
    test "creates a job with correct args" do
      {:ok, job} = Escalator.enqueue_step(1, 2, 3)

      assert job.args == %{"alert_id" => 1, "policy_id" => 2, "step_number" => 3}
      assert job.queue == "escalations"
    end

    test "supports schedule_in option" do
      {:ok, job} = Escalator.enqueue_step(1, 2, 3, schedule_in: 300)

      assert job.args == %{"alert_id" => 1, "policy_id" => 2, "step_number" => 3}
      # Job should be scheduled in the future
      assert job.scheduled_at != nil
    end
  end

  describe "job configuration" do
    test "uses escalations queue" do
      assert Escalator.__oban__(:queue) == :escalations
    end

    test "has max_attempts of 5" do
      assert Escalator.__oban__(:max_attempts) == 5
    end
  end

  describe "start_escalation/1" do
    test "returns error when no policy found" do
      alert = %{id: 1, team_id: nil}
      assert {:error, :no_policy} = Escalator.start_escalation(alert)
    end
  end
end
