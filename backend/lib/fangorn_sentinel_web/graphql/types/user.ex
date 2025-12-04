defmodule FangornSentinelWeb.GraphQL.Types.User do
  use Absinthe.Schema.Notation

  @desc "A user in the system"
  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :name, :string
    field :phone, :string
    field :timezone, :string
    field :role, :string

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc "Authentication session with JWT token"
  object :session do
    field :token, non_null(:string)
    field :user, non_null(:user)
  end

  @desc "Device platform"
  enum :device_platform do
    value :ios, description: "iOS device"
    value :android, description: "Android device"
  end

  @desc "Registered push notification device"
  object :device do
    field :id, non_null(:id)
    field :platform, non_null(:device_platform)
    field :device_token, non_null(:string)
    field :device_name, :string
    field :last_active_at, :datetime
    field :inserted_at, non_null(:datetime)
  end
end
