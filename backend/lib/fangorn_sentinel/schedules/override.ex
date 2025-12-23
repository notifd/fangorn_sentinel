defmodule FangornSentinel.Schedules.Override do
  @moduledoc """
  Schedule override schema for vacation, shift swaps, and temporary coverage.

  Override types:
  - "override" - General override (someone else covers)
  - "vacation" - User is on vacation
  - "swap" - Shift swap between users
  """

  use Ecto.Schema
  import Ecto.Changeset

  @override_types ~w(override vacation swap)

  schema "schedule_overrides" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :override_type, :string, default: "override"
    field :note, :string

    belongs_to :schedule, FangornSentinel.Schedules.Schedule
    belongs_to :user, FangornSentinel.Accounts.User
    belongs_to :created_by, FangornSentinel.Accounts.User

    timestamps()
  end

  @doc """
  Creates a changeset for a schedule override.
  """
  def changeset(override, attrs) do
    override
    |> cast(attrs, [:schedule_id, :user_id, :start_time, :end_time, :override_type, :note, :created_by_id])
    |> validate_required([:schedule_id, :user_id, :start_time, :end_time])
    |> validate_inclusion(:override_type, @override_types)
    |> validate_time_range()
    |> foreign_key_constraint(:schedule_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:created_by_id)
    |> check_constraint(:end_time, name: :end_time_after_start_time, message: "must be after start time")
  end

  defp validate_time_range(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && DateTime.compare(end_time, start_time) != :gt do
      add_error(changeset, :end_time, "must be after start time")
    else
      changeset
    end
  end

  @doc """
  Checks if this override is currently active.
  """
  def active?(%__MODULE__{start_time: start_time, end_time: end_time}, datetime \\ DateTime.utc_now()) do
    DateTime.compare(datetime, start_time) in [:gt, :eq] and
      DateTime.compare(datetime, end_time) == :lt
  end
end
