defmodule FangornSentinel.Repo.Migrations.CreateEscalationHistory do
  use Ecto.Migration

  def change do
    create table(:escalation_history) do
      add :alert_id, references(:alerts, on_delete: :delete_all), null: false
      add :policy_id, references(:escalation_policies, on_delete: :nilify_all)
      add :step_number, :integer, null: false
      add :action, :string, null: false
      add :notified_user_ids, {:array, :integer}, default: []
      add :channels_used, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:escalation_history, [:alert_id])
    create index(:escalation_history, [:policy_id])
    create index(:escalation_history, [:inserted_at])
  end
end
