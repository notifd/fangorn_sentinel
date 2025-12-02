defmodule FangornSentinel.Repo.Migrations.CreateEscalationPolicies do
  use Ecto.Migration

  def change do
    create table(:escalation_policies) do
      add :name, :string, null: false
      add :description, :text
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create index(:escalation_policies, [:team_id])

    create table(:escalation_steps) do
      add :step_number, :integer, null: false
      add :wait_minutes, :integer, default: 5
      add :notify_users, {:array, :integer}, default: []
      add :notify_schedules, {:array, :integer}, default: []
      add :channels, {:array, :string}, default: ["push"]
      add :policy_id, references(:escalation_policies, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:escalation_steps, [:policy_id])
    create unique_index(:escalation_steps, [:policy_id, :step_number])
  end
end
