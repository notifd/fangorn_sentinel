defmodule FangornSentinel.Schedules.RotationValidationTest do
  @moduledoc """
  Validation tests for Rotation on-call calculation.

  Testing edge cases and boundary conditions.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Schedules.Rotation

  describe "rotation calculation validation" do
    # FAILURES FOUND: 0
    test "handles empty participants list" do
      rotation = %Rotation{
        type: :daily,
        participants: [],  # Empty!
        rotation_start_date: ~D[2025-12-01]
      }

      # Should return nil, not crash
      result = Rotation.current_on_call(rotation, ~U[2025-12-05 10:00:00Z])

      # BUG if it crashes or returns something
      assert result == nil, "BUG: Empty participants should return nil"
    end

    # FAILURES FOUND: 0
    test "handles datetime before rotation start date" do
      rotation = %Rotation{
        type: :daily,
        participants: [1, 2, 3],
        rotation_start_date: ~D[2025-12-01]
      }

      # Query for datetime BEFORE rotation started
      datetime = ~U[2025-11-15 10:00:00Z]  # 16 days before

      result = Rotation.current_on_call(rotation, datetime)

      # Should handle gracefully - either nil or negative days handled correctly
      # BUG if it returns wrong participant due to negative modulo
      if result do
        # If it returns someone, verify it's valid
        assert result in rotation.participants,
          "BUG: Returned invalid participant for past date"
      end
    end

    # FAILURES FOUND: 0
    test "handles datetime 1000 years in future" do
      rotation = %Rotation{
        type: :daily,
        participants: [1, 2, 3],
        rotation_start_date: ~D[2025-12-01]
      }

      # Far future date
      datetime = ~U[3025-12-01 10:00:00Z]  # 1000 years from now

      # Should not crash with integer overflow
      assert_no_crash(fn ->
        result = Rotation.current_on_call(rotation, datetime)

        # Should return a valid participant
        assert result in rotation.participants,
          "BUG: Invalid participant for far future date"
      end)
    end

    # FAILURES FOUND: 0
    test "handles single participant rotation" do
      rotation = %Rotation{
        type: :daily,
        participants: [42],  # Only one person
        rotation_start_date: ~D[2025-12-01]
      }

      # Should always return that person
      result1 = Rotation.current_on_call(rotation, ~U[2025-12-01 10:00:00Z])
      result2 = Rotation.current_on_call(rotation, ~U[2025-12-10 10:00:00Z])
      result3 = Rotation.current_on_call(rotation, ~U[2026-01-01 10:00:00Z])

      assert result1 == 42
      assert result2 == 42
      assert result3 == 42
    end

    # FAILURES FOUND: 0
    test "handles weekly rotation with partial week at start" do
      rotation = %Rotation{
        type: :weekly,
        participants: [1, 2, 3],
        rotation_start_date: ~D[2025-12-03]  # Wednesday
      }

      # First week (partial - Wed-Sun)
      wed = Rotation.current_on_call(rotation, ~U[2025-12-03 10:00:00Z])
      sun = Rotation.current_on_call(rotation, ~U[2025-12-07 10:00:00Z])

      # Should be same person for first week
      assert wed == sun, "BUG: Different on-call within same week"

      # Second week (full week)
      mon = Rotation.current_on_call(rotation, ~U[2025-12-09 10:00:00Z])

      # Should rotate to next person
      assert mon != wed, "BUG: Didn't rotate to next person"
      assert mon in rotation.participants
    end

    # FAILURES FOUND: 0
    test "handles custom rotation with duration_hours = 1 (hourly rotation)" do
      rotation = %Rotation{
        type: :custom,
        participants: [1, 2, 3],
        duration_hours: 1,  # Rotate every hour
        rotation_start_date: ~D[2025-12-01]
      }

      # Hour 0
      hour0 = Rotation.current_on_call(rotation, ~U[2025-12-01 00:00:00Z])

      # Hour 1
      hour1 = Rotation.current_on_call(rotation, ~U[2025-12-01 01:00:00Z])

      # Hour 2
      hour2 = Rotation.current_on_call(rotation, ~U[2025-12-01 02:00:00Z])

      # Should all be different
      assert hour0 != hour1
      assert hour1 != hour2

      # All should be valid
      assert hour0 in rotation.participants
      assert hour1 in rotation.participants
      assert hour2 in rotation.participants
    end

    # FAILURES FOUND: 0
    test "handles custom rotation with duration_hours = 168 (weekly)" do
      rotation = %Rotation{
        type: :custom,
        participants: [1, 2],
        duration_hours: 168,  # 7 days = 168 hours
        rotation_start_date: ~D[2025-12-01]
      }

      week1 = Rotation.current_on_call(rotation, ~U[2025-12-01 10:00:00Z])
      week2 = Rotation.current_on_call(rotation, ~U[2025-12-08 10:00:00Z])

      # Should rotate after 7 days
      assert week1 != week2
      assert week1 in rotation.participants
      assert week2 in rotation.participants
    end

    # FAILURES FOUND: 0
    test "rejects invalid rotation type" do
      # This should fail at changeset level, but verify
      changeset = Rotation.changeset(%Rotation{}, %{
        name: "Test",
        type: :invalid_type,  # Not in valid types
        rotation_start_date: ~D[2025-12-01],
        schedule_id: 1
      })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).type
    end

    # FAILURES FOUND: 0
    test "rejects negative duration_hours" do
      changeset = Rotation.changeset(%Rotation{}, %{
        name: "Test",
        type: :custom,
        duration_hours: -5,  # Invalid
        rotation_start_date: ~D[2025-12-01],
        schedule_id: 1
      })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).duration_hours
    end

    # FAILURES FOUND: 0
    test "rejects duration_hours > 168 (1 week)" do
      changeset = Rotation.changeset(%Rotation{}, %{
        name: "Test",
        type: :custom,
        duration_hours: 200,  # > 1 week
        rotation_start_date: ~D[2025-12-01],
        schedule_id: 1
      })

      refute changeset.valid?
      assert "must be less than or equal to 168" in errors_on(changeset).duration_hours
    end
  end

  defp assert_no_crash(fun) do
    try do
      fun.()
    rescue
      e ->
        flunk("BUG: Function crashed: #{Exception.message(e)}")
    end
  end
end
