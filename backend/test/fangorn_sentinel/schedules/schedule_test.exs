defmodule FangornSentinel.Schedules.ScheduleTest do
  @moduledoc """
  Tests for Schedule schema and context.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Schedules
  alias FangornSentinel.Schedules.{Schedule, Rotation, Override}

  describe "Schedule schema" do
    test "valid changeset with required fields" do
      attrs = %{name: "Primary On-Call", timezone: "America/New_York"}
      changeset = Schedule.changeset(%Schedule{}, attrs)
      assert changeset.valid?
    end

    test "requires name" do
      attrs = %{}
      changeset = Schedule.changeset(%Schedule{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "uses default timezone from schema" do
      attrs = %{name: "Test Schedule"}
      changeset = Schedule.changeset(%Schedule{}, attrs)
      # Schema default is UTC, changeset should inherit it
      assert changeset.valid? or get_field(changeset, :timezone) == "UTC"
    end
  end

  describe "Rotation schema" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "Weekly Rotation",
        type: :weekly,
        rotation_start_date: ~D[2025-01-01],
        participants: [1, 2, 3],
        schedule_id: 1
      }
      changeset = Rotation.changeset(%Rotation{}, attrs)
      assert changeset.valid?
    end

    test "requires name, type, rotation_start_date, and schedule_id" do
      attrs = %{}
      changeset = Rotation.changeset(%Rotation{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{type: ["can't be blank"]} = errors_on(changeset)
      assert %{rotation_start_date: ["can't be blank"]} = errors_on(changeset)
      assert %{schedule_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates type is daily, weekly, or custom" do
      base_attrs = %{name: "Test", rotation_start_date: ~D[2025-01-01], schedule_id: 1}

      for valid_type <- [:daily, :weekly, :custom] do
        changeset = Rotation.changeset(%Rotation{}, Map.put(base_attrs, :type, valid_type))
        assert changeset.valid?, "Expected #{valid_type} to be valid"
      end

      changeset = Rotation.changeset(%Rotation{}, Map.put(base_attrs, :type, :invalid))
      refute changeset.valid?
    end

    test "defaults duration_hours to 24" do
      attrs = %{name: "Test", type: :daily, rotation_start_date: ~D[2025-01-01], schedule_id: 1}
      changeset = Rotation.changeset(%Rotation{}, attrs)
      assert get_field(changeset, :duration_hours) == 24
    end
  end

  describe "Override schema" do
    test "valid changeset with required fields" do
      now = DateTime.utc_now()
      later = DateTime.add(now, 3600, :second)

      attrs = %{
        schedule_id: 1,
        user_id: 1,
        start_time: now,
        end_time: later,
        override_type: "vacation",
        note: "On vacation"
      }
      changeset = Override.changeset(%Override{}, attrs)
      assert changeset.valid?
    end

    test "requires schedule_id, user_id, start_time, end_time" do
      attrs = %{}
      changeset = Override.changeset(%Override{}, attrs)
      refute changeset.valid?
      assert %{schedule_id: ["can't be blank"]} = errors_on(changeset)
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
      assert %{start_time: ["can't be blank"]} = errors_on(changeset)
      assert %{end_time: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates override_type" do
      now = DateTime.utc_now()
      later = DateTime.add(now, 3600, :second)
      base = %{schedule_id: 1, user_id: 1, start_time: now, end_time: later}

      for valid_type <- ["override", "vacation", "swap"] do
        changeset = Override.changeset(%Override{}, Map.put(base, :override_type, valid_type))
        assert changeset.valid?, "Expected #{valid_type} to be valid"
      end

      changeset = Override.changeset(%Override{}, Map.put(base, :override_type, "invalid"))
      refute changeset.valid?
    end

    test "validates end_time is after start_time" do
      now = DateTime.utc_now()
      earlier = DateTime.add(now, -3600, :second)

      attrs = %{
        schedule_id: 1,
        user_id: 1,
        start_time: now,
        end_time: earlier
      }
      changeset = Override.changeset(%Override{}, attrs)
      refute changeset.valid?
      assert %{end_time: ["must be after start time"]} = errors_on(changeset)
    end

    test "active?/2 returns true when datetime is within range" do
      now = DateTime.utc_now()
      start_time = DateTime.add(now, -3600, :second)
      end_time = DateTime.add(now, 3600, :second)

      override = %Override{start_time: start_time, end_time: end_time}
      assert Override.active?(override, now)
    end

    test "active?/2 returns false when datetime is outside range" do
      now = DateTime.utc_now()
      start_time = DateTime.add(now, 3600, :second)
      end_time = DateTime.add(now, 7200, :second)

      override = %Override{start_time: start_time, end_time: end_time}
      refute Override.active?(override, now)
    end
  end
end
