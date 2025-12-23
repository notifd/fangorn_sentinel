defmodule FangornSentinel.Workers.AlertRouterValidationTest do
  @moduledoc """
  Validation tests for AlertRouter worker.

  FAILURES FOUND: 3
  - Bug #19: Missing on_call_user_id crashes with FunctionClauseError
  - Bug #20: nil alert_id crashes with ArgumentError
  - Bug #23: Non-existent on_call_user_id crashes with Ecto.ConstraintError
  """
  use FangornSentinel.DataCase
  use Oban.Testing, repo: FangornSentinel.Repo

  alias FangornSentinel.Workers.AlertRouter
  alias FangornSentinel.Alerts

  describe "alert routing validation" do
    setup do
      {:ok, user} = FangornSentinel.Accounts.create_user(%{
        email: "router_test@example.com",
        password: "password123"
      })
      {:ok, alert} = Alerts.create_alert(%{
        title: "Test Alert",
        message: "Test message",
        severity: "critical",
        source: "test",
        status: "firing",
        fired_at: DateTime.utc_now()
      })
      %{user: user, alert: alert}
    end

    # FAILURES FOUND: 0
    test "handles non-existent alert_id gracefully" do
      result = perform_job(AlertRouter, %{alert_id: 999999, on_call_user_id: 1})

      # Should return error, not crash
      assert result == {:error, :alert_not_found}
    end

    # FAILURES FOUND: 1 (Bug #20 - ArgumentError on nil ID)
    test "handles nil alert_id" do
      # This should not crash the worker
      result = perform_job(AlertRouter, %{alert_id: nil, on_call_user_id: 1})

      # Should return error gracefully
      assert {:error, :invalid_alert_id} = result
    end

    # FAILURES FOUND: 0
    test "handles negative alert_id" do
      result = perform_job(AlertRouter, %{alert_id: -1, on_call_user_id: 1})

      # Should return error for invalid ID
      assert result == {:error, :invalid_alert_id}
    end

    # FAILURES FOUND: 1 (Bug #19 - FunctionClauseError on missing arg)
    test "handles missing on_call_user_id", %{alert: alert} do
      # Should handle gracefully, not crash
      result = perform_job(AlertRouter, %{alert_id: alert.id})

      # Should return error for missing on_call_user_id
      assert {:error, :missing_on_call_user_id} = result
    end

    # FAILURES FOUND: 1 (Bug #23 - FK constraint crashes)
    test "handles non-existent on_call_user_id", %{alert: alert} do
      result = perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: 999999})

      # Should handle gracefully - return user_not_found error
      assert result == {:error, :user_not_found}
    end

    # FAILURES FOUND: 0
    test "handles alert already assigned", %{alert: alert, user: user} do
      # First assign the alert
      {:ok, assigned_alert} = Alerts.update_alert(alert, %{assigned_to_id: user.id})

      result = perform_job(AlertRouter, %{
        alert_id: assigned_alert.id,
        on_call_user_id: user.id
      })

      # Should not re-assign
      assert result == :ok
    end

    # FAILURES FOUND: 0
    test "handles string alert_id instead of integer", %{alert: alert, user: user} do
      # String ID from JSON parsing - now returns error since we validate integers
      result = perform_job(AlertRouter, %{
        "alert_id" => to_string(alert.id),
        "on_call_user_id" => to_string(user.id)
      })

      # Strings are rejected - must be integers
      assert {:error, :invalid_alert_id} = result
    end
  end
end
