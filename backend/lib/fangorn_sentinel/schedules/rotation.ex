defmodule FangornSentinel.Schedules.Rotation do
  @moduledoc """
  Schema for schedule rotations - defines the pattern of on-call shifts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @rotation_types [:daily, :weekly, :custom]

  schema "rotations" do
    field :name, :string
    field :type, Ecto.Enum, values: @rotation_types
    field :start_time, :time
    field :duration_hours, :integer, default: 24
    field :participants, {:array, :integer}, default: []
    field :rotation_start_date, :date

    belongs_to :schedule, FangornSentinel.Schedules.Schedule

    timestamps()
  end

  @doc false
  def changeset(rotation, attrs) do
    rotation
    |> cast(attrs, [:name, :type, :start_time, :duration_hours, :participants, :rotation_start_date, :schedule_id])
    |> validate_required([:name, :type, :rotation_start_date, :schedule_id])
    |> validate_inclusion(:type, @rotation_types)
    |> validate_number(:duration_hours, greater_than: 0, less_than_or_equal_to: 168)
    |> foreign_key_constraint(:schedule_id)
  end

  @doc """
  Calculate who is currently on call for this rotation.

  Optionally accepts a timezone to interpret the rotation start date.
  If no timezone is provided, UTC is assumed.
  """
  # Function head with defaults
  def current_on_call(rotation, datetime \\ DateTime.utc_now(), timezone \\ "UTC")

  def current_on_call(%__MODULE__{participants: []}, _datetime, _timezone), do: nil

  def current_on_call(%__MODULE__{} = rotation, datetime, timezone) do
    # Convert datetime to the schedule's timezone for calculation
    local_datetime = to_local_datetime(datetime, timezone)

    # Handle negative days (datetime before rotation start)
    start_datetime = DateTime.new!(rotation.rotation_start_date, ~T[00:00:00], timezone)
    |> case do
      {:ok, dt} -> dt
      {:ambiguous, dt, _} -> dt  # Use first interpretation for ambiguous times
      {:gap, _, dt} -> dt  # Use later time for gaps
      _ -> DateTime.new!(rotation.rotation_start_date, ~T[00:00:00])  # Fallback to UTC
    end

    if DateTime.compare(local_datetime, start_datetime) == :lt do
      # Before rotation started - return nil or first participant
      nil
    else
      calculate_on_call(rotation, local_datetime, start_datetime)
    end
  end

  defp to_local_datetime(datetime, "UTC"), do: datetime
  defp to_local_datetime(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, local} -> local
      {:error, _} -> datetime  # Fallback to original if timezone invalid
    end
  end

  defp calculate_on_call(rotation, datetime, start_datetime) do
    case rotation.type do
      :daily ->
        days_since_start = Date.diff(DateTime.to_date(datetime), rotation.rotation_start_date)
        participant_index = rem(days_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :weekly ->
        days_since_start = Date.diff(DateTime.to_date(datetime), rotation.rotation_start_date)
        weeks_since_start = div(days_since_start, 7)
        participant_index = rem(weeks_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :custom ->
        # For custom rotations, use actual elapsed time including hours
        seconds_since_start = DateTime.diff(datetime, start_datetime, :second)
        hours_since_start = div(seconds_since_start, 3600)
        shifts_since_start = div(hours_since_start, rotation.duration_hours)
        participant_index = rem(shifts_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)
    end
  end
end
