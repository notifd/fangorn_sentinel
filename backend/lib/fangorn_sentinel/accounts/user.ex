defmodule FangornSentinel.Accounts.User do
  @moduledoc """
  User schema - minimal implementation for Phase 1.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :phone, :string
    field :timezone, :string, default: "UTC"
    field :encrypted_password, :string
    field :role, :string, default: "user"
    field :confirmed_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :phone, :timezone, :encrypted_password, :role, :confirmed_at])
    |> validate_required([:email, :encrypted_password])
    |> unique_constraint(:email)
  end
end
