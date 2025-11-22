defmodule FangornSentinel.Workers.NotifierTest do
  use FangornSentinel.DataCase
  use Oban.Testing, repo: FangornSentinel.Repo

  alias FangornSentinel.Workers.Notifier
  alias FangornSentinel.Alerts
  alias FangornSentinel.Accounts.User
  alias FangornSentinel.Push.PushDevice
  alias FangornSentinel.Repo

  setup do
    # Create test user
    user =
      %User{}
      |> User.changeset(%{
        email: "oncall@example.com",
        name: "On-Call Engineer",
        encrypted_password: "hashed_password"
      })
      |> Repo.insert!()

    # Create test alert
    {:ok, alert} =
      Alerts.create_alert(%{
        title: "Test Alert",
        message: "This is a test alert",
        severity: "critical",
        source: "test",
        fired_at: DateTime.utc_now()
      })

    {:ok, user: user, alert: alert}
  end

  describe "perform/1" do
    test "sends push notification to user's devices", %{user: user, alert: alert} do
      # Register iOS device
      {:ok, _ios_device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "ios_token_123"
        })
        |> Repo.insert()

      # Register Android device
      {:ok, _android_device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "android",
          device_token: "android_token_456"
        })
        |> Repo.insert()

      # Perform notification job
      assert :ok = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})
    end

    test "handles user with no devices gracefully", %{user: user, alert: alert} do
      # User has no registered devices
      assert :ok = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})
    end

    test "only sends to enabled devices", %{user: user, alert: alert} do
      # Register enabled device
      {:ok, _enabled_device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "enabled_token",
          enabled: true
        })
        |> Repo.insert()

      # Register disabled device
      {:ok, _disabled_device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "disabled_token",
          enabled: false
        })
        |> Repo.insert()

      # Should only send to enabled device
      assert :ok = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})
    end

    test "handles alert not found", %{user: user} do
      assert {:error, :alert_not_found} =
               perform_job(Notifier, %{alert_id: 99999, user_id: user.id})
    end

    test "handles user not found", %{alert: alert} do
      assert {:error, :user_not_found} =
               perform_job(Notifier, %{alert_id: alert.id, user_id: 99999})
    end
  end

  describe "enqueue_for_alert/2" do
    test "enqueues a notification job", %{alert: alert, user: user} do
      assert {:ok, %Oban.Job{}} = Notifier.enqueue_for_alert(alert.id, user.id)

      assert_enqueued worker: Notifier, args: %{alert_id: alert.id, user_id: user.id}
    end

    test "allows scheduling for later", %{alert: alert, user: user} do
      assert {:ok, %Oban.Job{} = job} =
               Notifier.enqueue_for_alert(alert.id, user.id, schedule_in: 60)

      assert_enqueued worker: Notifier, args: %{alert_id: alert.id, user_id: user.id}

      # Verify job is scheduled in future
      assert job.scheduled_at != nil
      assert DateTime.compare(job.scheduled_at, DateTime.utc_now()) == :gt
    end
  end
end
