defmodule FangornSentinel.Accounts.Team do
  @moduledoc """
  Schema for teams - groups of users that share schedules and escalation policies.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :slug, :string
    field :description, :string

    has_many :schedules, FangornSentinel.Schedules.Schedule
    has_many :escalation_policies, FangornSentinel.Escalation.Policy

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and dashes"
    )
    |> unique_constraint(:slug)
  end
end
