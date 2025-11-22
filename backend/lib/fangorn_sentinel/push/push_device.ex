defmodule FangornSentinel.Push.PushDevice do
  @moduledoc """
  Schema for storing mobile device push notification tokens.

  Each user can have multiple devices (iOS and Android) registered for push notifications.
  Devices can be enabled/disabled for notifications.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_platforms ~w(ios android)

  schema "push_devices" do
    field :platform, :string
    field :device_token, :string
    field :device_name, :string
    field :app_version, :string
    field :os_version, :string
    field :enabled, :boolean, default: true
    field :last_active_at, :utc_datetime

    belongs_to :user, FangornSentinel.Accounts.User

    timestamps()
  end

  @doc """
  Changeset for creating or updating a push device.
  """
  def changeset(device, attrs) do
    device
    |> cast(attrs, [
      :user_id,
      :platform,
      :device_token,
      :device_name,
      :app_version,
      :os_version,
      :enabled,
      :last_active_at
    ])
    |> validate_required([:user_id, :platform, :device_token])
    |> validate_inclusion(:platform, @valid_platforms)
    |> unique_constraint(:device_token)
    |> foreign_key_constraint(:user_id)
  end
end
