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
    field :password, :string, virtual: true
    field :role, :string, default: "user"
    field :confirmed_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :phone, :timezone, :role, :confirmed_at])
    |> validate_required([:email])
    |> validate_email()
    |> unique_constraint(:email)
  end

  @doc "Changeset for user registration with password"
  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s\x00-\x1F\x7F]+@[^\s\x00-\x1F\x7F]+$/,
      message: "must have the @ sign and no spaces or control characters")
    |> validate_length(:email, max: 160)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:encrypted_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Changeset for password changes (reset password).
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  @doc """
  Changeset for confirming the user email.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%__MODULE__{encrypted_password: encrypted_password}, password)
      when is_binary(encrypted_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, encrypted_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
