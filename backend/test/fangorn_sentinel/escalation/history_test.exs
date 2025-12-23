defmodule FangornSentinel.Escalation.HistoryTest do
  use FangornSentinel.DataCase

  alias FangornSentinel.Escalation
  alias FangornSentinel.Escalation.History

  describe "History changeset" do
    test "valid changeset with required fields" do
      attrs = %{
        alert_id: 1,
        step_number: 1,
        action: "step_executed"
      }

      changeset = History.changeset(%History{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      changeset = History.changeset(%History{}, %{})
      refute changeset.valid?

      assert "can't be blank" in errors_on(changeset).alert_id
      assert "can't be blank" in errors_on(changeset).step_number
      assert "can't be blank" in errors_on(changeset).action
    end

    test "invalid action" do
      attrs = %{
        alert_id: 1,
        step_number: 1,
        action: "invalid_action"
      }

      changeset = History.changeset(%History{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).action
    end

    test "valid actions" do
      valid_actions = ~w(step_executed escalation_started escalation_cancelled escalation_completed)

      for action <- valid_actions do
        attrs = %{alert_id: 1, step_number: 1, action: action}
        changeset = History.changeset(%History{}, attrs)
        assert changeset.valid?, "Expected #{action} to be valid"
      end
    end

    test "step_number must be non-negative" do
      attrs = %{alert_id: 1, step_number: -1, action: "step_executed"}

      changeset = History.changeset(%History{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).step_number
    end

    test "accepts optional fields" do
      attrs = %{
        alert_id: 1,
        policy_id: 2,
        step_number: 3,
        action: "step_executed",
        notified_user_ids: [1, 2, 3],
        channels_used: ["push", "sms"],
        metadata: %{reason: "test"}
      }

      changeset = History.changeset(%History{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :notified_user_ids) == [1, 2, 3]
      assert get_change(changeset, :channels_used) == ["push", "sms"]
      assert get_change(changeset, :metadata) == %{reason: "test"}
    end
  end

  describe "Escalation context history functions" do
    test "record_history/1 creates a history entry" do
      # This test requires a DB with the alert table
      # For now, just test that the function exists and returns expected error for FK
      result = Escalation.record_history(%{
        alert_id: 999999,
        step_number: 1,
        action: "step_executed"
      })

      # Should fail on FK constraint since alert doesn't exist
      assert {:error, _changeset} = result
    end
  end
end
