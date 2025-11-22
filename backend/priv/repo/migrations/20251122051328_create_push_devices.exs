defmodule FangornSentinel.Repo.Migrations.CreatePushDevices do
  use Ecto.Migration

  def change do
    create table(:push_devices) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :platform, :string, null: false
      add :device_token, :string, null: false
      add :device_name, :string
      add :app_version, :string
      add :os_version, :string
      add :enabled, :boolean, default: true, null: false
      add :last_active_at, :utc_datetime

      timestamps()
    end

    create unique_index(:push_devices, [:device_token])
    create index(:push_devices, [:user_id])
    create index(:push_devices, [:user_id, :enabled])
  end
end
