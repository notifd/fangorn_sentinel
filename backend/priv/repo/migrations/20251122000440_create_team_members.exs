defmodule FangornSentinel.Repo.Migrations.CreateTeamMembers do
  use Ecto.Migration

  def change do
    create table(:team_members, primary_key: false) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, default: "member"

      timestamps()
    end

    create unique_index(:team_members, [:team_id, :user_id])
    create index(:team_members, [:user_id])
  end
end
