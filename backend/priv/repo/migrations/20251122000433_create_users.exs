defmodule FangornSentinel.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :phone, :string
      add :timezone, :string, default: "UTC"
      add :encrypted_password, :string, null: false
      add :role, :string, default: "user"
      add :confirmed_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
  end
end
