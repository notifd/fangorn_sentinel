defmodule FangornSentinel.Schedules.Schedule do
  @moduledoc """
  Schema for on-call schedules.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :name, :string
    field :description, :string
    field :timezone, :string, default: "UTC"

    belongs_to :team, FangornSentinel.Accounts.Team
    has_many :rotations, FangornSentinel.Schedules.Rotation

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:name, :description, :timezone, :team_id])
    |> validate_required([:name, :timezone])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:team_id)
  end
end
