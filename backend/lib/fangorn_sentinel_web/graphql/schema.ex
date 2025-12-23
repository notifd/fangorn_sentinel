defmodule FangornSentinelWeb.GraphQL.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom
  import_types FangornSentinelWeb.GraphQL.Types.Alert
  import_types FangornSentinelWeb.GraphQL.Types.User
  import_types FangornSentinelWeb.GraphQL.Types.Schedule

  alias FangornSentinelWeb.GraphQL.Resolvers

  query do
    @desc "Get current user"
    field :me, :user do
      resolve &Resolvers.User.me/3
    end

    @desc "List alerts"
    field :alerts, list_of(:alert) do
      arg :status, :alert_status
      arg :severity, :alert_severity
      arg :limit, :integer, default_value: 50
      arg :offset, :integer, default_value: 0

      resolve &Resolvers.Alert.list_alerts/3
    end

    @desc "Get alert by ID"
    field :alert, :alert do
      arg :id, non_null(:id)

      resolve &Resolvers.Alert.get_alert/3
    end

    @desc "Get current on-call schedule"
    field :who_is_on_call, list_of(:user) do
      arg :team_id, :id

      resolve &Resolvers.Schedule.who_is_on_call/3
    end

    @desc "Get my current schedule"
    field :my_schedule, :schedule do
      resolve &Resolvers.Schedule.my_schedule/3
    end

    @desc "List my registered devices"
    field :my_devices, list_of(:device) do
      resolve &Resolvers.Device.list_devices/3
    end
  end

  mutation do
    @desc "Authenticate user and get JWT token"
    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve &Resolvers.User.login/3
    end

    @desc "Register device for push notifications"
    field :register_device, :device do
      arg :token, non_null(:string)
      arg :platform, non_null(:device_platform)
      arg :device_name, :string

      resolve &Resolvers.Device.register/3
    end

    @desc "Unregister a device from push notifications"
    field :unregister_device, :boolean do
      arg :token, non_null(:string)

      resolve &Resolvers.Device.unregister/3
    end

    @desc "Acknowledge an alert"
    field :acknowledge_alert, :alert do
      arg :alert_id, non_null(:id)
      arg :note, :string

      resolve &Resolvers.Alert.acknowledge/3
    end

    @desc "Resolve an alert"
    field :resolve_alert, :alert do
      arg :alert_id, non_null(:id)
      arg :resolution_note, :string

      resolve &Resolvers.Alert.resolve/3
    end
  end

  subscription do
    @desc "Subscribe to new alerts for current user"
    field :alert_created, :alert do
      arg :team_id, :id

      config fn args, %{context: %{current_user: user}} ->
        topic = if args[:team_id] do
          "alerts:team:#{args[:team_id]}"
        else
          "alerts:user:#{user.id}"
        end

        {:ok, topic: topic}
      end

      trigger :create_alert, topic: fn alert ->
        ["alerts:team:#{alert.team_id}", "alerts:user:#{alert.assigned_to_id}"]
      end
    end

    @desc "Subscribe to alert updates"
    field :alert_updated, :alert do
      arg :alert_id, non_null(:id)

      config fn args, _context ->
        {:ok, topic: "alert:#{args[:alert_id]}"}
      end

      trigger [:acknowledge_alert, :resolve_alert], topic: fn alert ->
        "alert:#{alert.id}"
      end
    end
  end

  def context(ctx) do
    ctx
  end

  def plugins do
    Absinthe.Plugin.defaults()
  end
end
