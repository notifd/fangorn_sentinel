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
  """
  def current_on_call(%__MODULE__{participants: []} = _rotation, _datetime), do: nil

  def current_on_call(%__MODULE__{} = rotation, datetime \\ DateTime.utc_now()) do
    days_since_start = Date.diff(DateTime.to_date(datetime), rotation.rotation_start_date)

    case rotation.type do
      :daily ->
        participant_index = rem(days_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :weekly ->
        weeks_since_start = div(days_since_start, 7)
        participant_index = rem(weeks_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :custom ->
        # For custom rotations, use duration_hours to calculate
        hours_since_start = days_since_start * 24
        shifts_since_start = div(hours_since_start, rotation.duration_hours)
        participant_index = rem(shifts_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)
    end
  end
end
