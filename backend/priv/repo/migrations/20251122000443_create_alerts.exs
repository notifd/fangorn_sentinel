defmodule FangornSentinel.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :title, :string, null: false
      add :message, :text
      add :severity, :string, null: false
      add :source, :string, null: false
      add :source_id, :string
      add :labels, :map, default: %{}
      add :annotations, :map, default: %{}
      add :status, :string, null: false, default: "firing"
      add :fired_at, :utc_datetime, null: false
      add :acknowledged_at, :utc_datetime
      add :resolved_at, :utc_datetime

      add :assigned_to_id, references(:users, on_delete: :nilify_all)
      add :acknowledged_by_id, references(:users, on_delete: :nilify_all)
      add :resolved_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:alerts, [:status])
    create index(:alerts, [:severity])
    create index(:alerts, [:source])
    create index(:alerts, [:fired_at])
    create index(:alerts, [:assigned_to_id])
    create index(:alerts, [:source, :source_id])
  end
end
