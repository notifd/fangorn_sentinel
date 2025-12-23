defmodule FangornSentinel.Alerts.Alert do
  @moduledoc """
  Schema for alerts received from various sources (Grafana, Prometheus, webhooks, etc.)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          title: String.t(),
          message: String.t() | nil,
          severity: String.t(),
          source: String.t(),
          source_id: String.t() | nil,
          labels: map(),
          annotations: map(),
          status: String.t(),
          fired_at: DateTime.t(),
          acknowledged_at: DateTime.t() | nil,
          resolved_at: DateTime.t() | nil,
          assigned_to_id: integer() | nil,
          acknowledged_by_id: integer() | nil,
          resolved_by_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @valid_severities ~w(critical warning info)
  @valid_statuses ~w(firing acknowledged resolved)

  schema "alerts" do
    field :title, :string
    field :message, :string
    field :severity, :string
    field :source, :string
    field :source_id, :string
    field :labels, :map, default: %{}
    field :annotations, :map, default: %{}
    field :status, :string, default: "firing"
    field :fired_at, :utc_datetime
    field :acknowledged_at, :utc_datetime
    field :resolved_at, :utc_datetime

    # Foreign key references (will be properly set up with belongs_to later)
    field :assigned_to_id, :integer
    field :acknowledged_by_id, :integer
    field :resolved_by_id, :integer

    timestamps()
  end

  @doc """
  Changeset for creating or updating an alert.
  """
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [
      :title,
      :message,
      :severity,
      :source,
      :source_id,
      :labels,
      :annotations,
      :status,
      :fired_at,
      :assigned_to_id
    ])
    |> validate_required([:title, :severity, :source, :fired_at])
    |> validate_length(:title, min: 1, max: 1000)
    |> validate_length(:message, max: 10_000)
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_inclusion(:status, @valid_statuses)
    |> put_defaults()
  end

  @doc """
  Changeset for acknowledging an alert.
  """
  def acknowledge_changeset(alert, attrs) do
    alert
    |> cast(attrs, [:acknowledged_by_id])
    |> validate_required([:acknowledged_by_id])
    |> put_change(:status, "acknowledged")
    |> put_change(:acknowledged_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for resolving an alert.
  """
  def resolve_changeset(alert, attrs) do
    alert
    |> cast(attrs, [:resolved_by_id])
    |> validate_required([:resolved_by_id])
    |> put_change(:status, "resolved")
    |> put_change(:resolved_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp put_defaults(changeset) do
    changeset
    |> put_default_if_missing(:status, "firing")
    |> put_default_if_missing(:labels, %{})
    |> put_default_if_missing(:annotations, %{})
  end

  defp put_default_if_missing(changeset, field, default_value) do
    # Only set default if the field wasn't provided in attrs (not in changes)
    if Map.has_key?(changeset.changes, field) do
      changeset
    else
      put_change(changeset, field, default_value)
    end
  end
end
