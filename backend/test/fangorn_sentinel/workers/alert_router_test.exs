defmodule FangornSentinel.Workers.AlertRouterTest do
  use FangornSentinel.DataCase
  use Oban.Testing, repo: FangornSentinel.Repo

  alias FangornSentinel.Workers.AlertRouter
  alias FangornSentinel.Alerts
  alias FangornSentinel.Accounts.User
  alias FangornSentinel.Repo

  setup do
    # Create a test user for alert assignment
    user =
      %User{}
      |> User.changeset(%{
        email: "oncall@example.com",
        name: "On-Call Engineer",
        encrypted_password: "hashed_password"
      })
      |> Repo.insert!()

    {:ok, user: user}
  end

  describe "perform/1" do
    test "routes alert to on-call user (basic implementation)", %{user: user} do
      # Create an unassigned alert
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Test Alert",
          severity: "critical",
          source: "grafana",
          fired_at: DateTime.utc_now()
        })

      # Enqueue and perform the job
      assert :ok =
               perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: user.id})

      # Verify alert was assigned
      {:ok, updated_alert} = Alerts.get_alert(alert.id)
      assert updated_alert.assigned_to_id == user.id
    end

    test "does nothing if alert is already assigned", %{user: user} do
      # Create an already-assigned alert
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Assigned Alert",
          severity: "warning",
          source: "test",
          fired_at: DateTime.utc_now(),
          assigned_to_id: user.id
        })

      original_assigned_to_id = alert.assigned_to_id

      # Perform the job
      assert :ok =
               perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: 999})

      # Verify assignment didn't change
      {:ok, updated_alert} = Alerts.get_alert(alert.id)
      assert updated_alert.assigned_to_id == original_assigned_to_id
    end

    test "handles alert not found gracefully" do
      # Attempt to route non-existent alert
      assert {:error, :alert_not_found} =
               perform_job(AlertRouter, %{alert_id: 99999, on_call_user_id: 1})
    end

    test "does not route resolved alerts", %{user: user} do
      # Create a resolved alert
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Resolved Alert",
          severity: "info",
          source: "test",
          status: "resolved",
          fired_at: DateTime.utc_now()
        })

      # Attempt to route
      assert :ok =
               perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: user.id})

      # Verify alert was NOT assigned (still nil)
      {:ok, updated_alert} = Alerts.get_alert(alert.id)
      assert updated_alert.assigned_to_id == nil
    end

    test "does not route acknowledged alerts", %{user: user} do
      # Create and acknowledge an alert
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Acknowledged Alert",
          severity: "warning",
          source: "test",
          status: "acknowledged",
          fired_at: DateTime.utc_now()
        })

      # Attempt to route
      assert :ok =
               perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: user.id})

      # Verify alert was NOT assigned (still nil)
      {:ok, updated_alert} = Alerts.get_alert(alert.id)
      assert updated_alert.assigned_to_id == nil
    end

    test "enqueues notification job after routing", %{user: user} do
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Test Alert",
          severity: "critical",
          source: "test",
          fired_at: DateTime.utc_now()
        })

      # Perform routing job
      assert :ok =
               perform_job(AlertRouter, %{alert_id: alert.id, on_call_user_id: user.id})

      # Verify alert was assigned
      {:ok, updated_alert} = Alerts.get_alert(alert.id)
      assert updated_alert.assigned_to_id == user.id

      # Verify notification job was enqueued
      assert_enqueued worker: FangornSentinel.Workers.Notifier,
                      args: %{alert_id: alert.id, user_id: user.id}
    end
  end

  describe "enqueue_for_alert/2" do
    test "enqueues a routing job for an alert", %{user: user} do
      {:ok, alert} =
        Alerts.create_alert(%{
          title: "Test",
          severity: "warning",
          source: "test",
          fired_at: DateTime.utc_now()
        })

      assert {:ok, %Oban.Job{}} = AlertRouter.enqueue_for_alert(alert.id, user.id)

      # Verify job is in the queue
      assert_enqueued worker: AlertRouter, args: %{alert_id: alert.id, on_call_user_id: user.id}
    end

    test "allows scheduling for later" do
      assert {:ok, %Oban.Job{} = job} = AlertRouter.enqueue_for_alert(123, 456, schedule_in: 60)

      # Verify job is scheduled in the future
      assert_enqueued worker: AlertRouter,
                      args: %{alert_id: 123, on_call_user_id: 456}

      # Check that scheduled_at is set to future time
      assert job.scheduled_at != nil
      assert DateTime.compare(job.scheduled_at, DateTime.utc_now()) == :gt
    end
  end
end
