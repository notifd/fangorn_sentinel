defmodule FangornSentinel.Schedules do
  @moduledoc """
  The Schedules context - manages on-call schedules and rotations.
  """

  import Ecto.Query, warn: false
  alias FangornSentinel.Repo
  alias FangornSentinel.Schedules.{Schedule, Rotation, Override}

  @doc """
  Returns the list of schedules.
  """
  def list_schedules do
    Repo.all(Schedule)
  end

  @doc """
  Gets a single schedule.
  """
  def get_schedule!(id), do: Repo.get!(Schedule, id)

  @doc """
  Gets a schedule with its rotations preloaded.
  """
  def get_schedule_with_rotations!(id) do
    Schedule
    |> Repo.get!(id)
    |> Repo.preload(:rotations)
  end

  @doc """
  Creates a schedule.
  """
  def create_schedule(attrs \\ %{}) do
    %Schedule{}
    |> Schedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a schedule.
  """
  def update_schedule(%Schedule{} = schedule, attrs) do
    schedule
    |> Schedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a schedule.
  """
  def delete_schedule(%Schedule{} = schedule) do
    Repo.delete(schedule)
  end

  @doc """
  Creates a rotation for a schedule.
  """
  def create_rotation(attrs \\ %{}) do
    %Rotation{}
    |> Rotation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the user ID of who is currently on call for a given schedule.
  """
  def who_is_on_call(schedule_id, datetime \\ DateTime.utc_now()) do
    schedule = get_schedule_with_rotations!(schedule_id)

    schedule.rotations
    |> Enum.map(&Rotation.current_on_call(&1, datetime))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc """
  Returns the user ID of who is currently on call for a given team.
  """
  def who_is_on_call_for_team(team_id, datetime \\ DateTime.utc_now()) do
    Schedule
    |> where([s], s.team_id == ^team_id)
    |> Repo.all()
    |> Repo.preload(:rotations)
    |> Enum.flat_map(fn schedule ->
      schedule.rotations
      |> Enum.map(&Rotation.current_on_call(&1, datetime))
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  # Override functions

  @doc """
  Lists all overrides for a schedule.
  """
  def list_overrides(schedule_id) do
    Override
    |> where([o], o.schedule_id == ^schedule_id)
    |> order_by([o], desc: o.start_time)
    |> Repo.all()
  end

  @doc """
  Gets active overrides for a schedule at a given time.
  """
  def get_active_overrides(schedule_id, datetime \\ DateTime.utc_now()) do
    Override
    |> where([o], o.schedule_id == ^schedule_id)
    |> where([o], o.start_time <= ^datetime and o.end_time > ^datetime)
    |> Repo.all()
  end

  @doc """
  Creates a schedule override.
  """
  def create_override(attrs \\ %{}) do
    %Override{}
    |> Override.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an override.
  """
  def update_override(%Override{} = override, attrs) do
    override
    |> Override.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an override.
  """
  def delete_override(%Override{} = override) do
    Repo.delete(override)
  end

  @doc """
  Returns who is on call, considering overrides.
  Overrides take precedence over regular rotation.
  """
  def who_is_on_call_with_overrides(schedule_id, datetime \\ DateTime.utc_now()) do
    # Check for active overrides first
    active_overrides = get_active_overrides(schedule_id, datetime)

    if Enum.any?(active_overrides) do
      # Return override users
      active_overrides
      |> Enum.map(& &1.user_id)
      |> Enum.uniq()
    else
      # Fall back to regular rotation
      who_is_on_call(schedule_id, datetime)
    end
  end
end
