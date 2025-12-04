defmodule FangornSentinel.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add :name, :string, null: false
      add :description, :text
      add :timezone, :string, null: false, default: "UTC"
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create index(:schedules, [:team_id])

    create table(:rotations) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :start_time, :time
      add :duration_hours, :integer, default: 24
      add :participants, {:array, :integer}, default: []
      add :rotation_start_date, :date, null: false
      add :schedule_id, references(:schedules, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rotations, [:schedule_id])
  end
end
