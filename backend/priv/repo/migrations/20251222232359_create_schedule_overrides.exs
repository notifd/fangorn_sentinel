defmodule FangornSentinel.Repo.Migrations.CreateScheduleOverrides do
  use Ecto.Migration

  def change do
    create table(:schedule_overrides) do
      add :schedule_id, references(:schedules, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :override_type, :string, null: false, default: "override"
      add :note, :text
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:schedule_overrides, [:schedule_id])
    create index(:schedule_overrides, [:user_id])
    create index(:schedule_overrides, [:start_time, :end_time])
    create constraint(:schedule_overrides, :end_time_after_start_time, check: "end_time > start_time")
  end
end
