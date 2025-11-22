defmodule FangornSentinel.AlertsTest do
  use FangornSentinel.DataCase

  alias FangornSentinel.Alerts
  alias FangornSentinel.Alerts.Alert
  alias FangornSentinel.Accounts.User
  alias FangornSentinel.Repo

  setup do
    # Create a test user for foreign key constraints
    user =
      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        encrypted_password: "hashed_password"
      })
      |> Repo.insert!()

    {:ok, user: user}
  end

  describe "create_alert/1" do
    test "creates alert with valid attributes" do
      attrs = %{
        title: "High CPU Usage",
        message: "CPU usage above 90% for 5 minutes",
        severity: "critical",
        source: "grafana",
        source_id: "alert-123",
        fired_at: DateTime.utc_now()
      }

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(attrs)
      assert alert.title == "High CPU Usage"
      assert alert.severity == "critical"
      assert alert.source == "grafana"
      assert alert.status == "firing"
    end

    test "creates alert with labels and annotations" do
      attrs = %{
        title: "Database Connection Failed",
        severity: "critical",
        source: "prometheus",
        fired_at: DateTime.utc_now(),
        labels: %{"service" => "postgres", "environment" => "production"},
        annotations: %{"runbook" => "https://wiki.example.com/db-down"}
      }

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(attrs)
      assert alert.labels == %{"service" => "postgres", "environment" => "production"}
      assert alert.annotations == %{"runbook" => "https://wiki.example.com/db-down"}
    end

    test "returns error with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = Alerts.create_alert(%{})
    end

    test "returns error with invalid severity" do
      attrs = %{
        title: "Test",
        severity: "invalid",
        source: "test",
        fired_at: DateTime.utc_now()
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Alerts.create_alert(attrs)
      assert %{severity: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "list_alerts/1" do
    test "returns all alerts" do
      alert1 = create_alert(%{title: "Alert 1", severity: "critical"})
      alert2 = create_alert(%{title: "Alert 2", severity: "warning"})

      alerts = Alerts.list_alerts()

      assert length(alerts) == 2
      assert Enum.any?(alerts, fn a -> a.id == alert1.id end)
      assert Enum.any?(alerts, fn a -> a.id == alert2.id end)
    end

    test "filters alerts by status" do
      firing_alert = create_alert(%{title: "Firing", status: "firing"})
      _resolved_alert = create_alert(%{title: "Resolved", status: "resolved"})

      alerts = Alerts.list_alerts(status: "firing")

      assert length(alerts) == 1
      assert hd(alerts).id == firing_alert.id
    end

    test "filters alerts by severity" do
      critical_alert = create_alert(%{title: "Critical", severity: "critical"})
      _warning_alert = create_alert(%{title: "Warning", severity: "warning"})

      alerts = Alerts.list_alerts(severity: "critical")

      assert length(alerts) == 1
      assert hd(alerts).id == critical_alert.id
    end

    test "limits number of alerts returned" do
      for i <- 1..10 do
        create_alert(%{title: "Alert #{i}"})
      end

      alerts = Alerts.list_alerts(limit: 5)

      assert length(alerts) == 5
    end

    test "orders alerts by fired_at descending by default" do
      older_time = DateTime.utc_now() |> DateTime.add(-3600, :second)
      newer_time = DateTime.utc_now()

      older_alert = create_alert(%{title: "Older", fired_at: older_time})
      newer_alert = create_alert(%{title: "Newer", fired_at: newer_time})

      alerts = Alerts.list_alerts()

      assert hd(alerts).id == newer_alert.id
      assert List.last(alerts).id == older_alert.id
    end
  end

  describe "get_alert/1" do
    test "returns alert by id" do
      alert = create_alert(%{title: "Test Alert"})

      assert {:ok, found_alert} = Alerts.get_alert(alert.id)
      assert found_alert.id == alert.id
      assert found_alert.title == "Test Alert"
    end

    test "returns error when alert not found" do
      assert {:error, :not_found} = Alerts.get_alert(99999)
    end
  end

  describe "get_alert!/1" do
    test "returns alert by id" do
      alert = create_alert(%{title: "Test Alert"})

      found_alert = Alerts.get_alert!(alert.id)
      assert found_alert.id == alert.id
    end

    test "raises when alert not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Alerts.get_alert!(99999)
      end
    end
  end

  describe "acknowledge_alert/2" do
    test "acknowledges a firing alert", %{user: user} do
      alert = create_alert(%{title: "Test", status: "firing"})

      assert {:ok, acknowledged_alert} = Alerts.acknowledge_alert(alert.id, user_id: user.id)
      assert acknowledged_alert.status == "acknowledged"
      assert acknowledged_alert.acknowledged_by_id == user.id
      assert acknowledged_alert.acknowledged_at != nil
    end

    test "requires user_id" do
      alert = create_alert(%{title: "Test"})

      assert {:error, %Ecto.Changeset{} = changeset} = Alerts.acknowledge_alert(alert.id, [])
      assert %{acknowledged_by_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when alert not found", %{user: user} do
      assert {:error, :not_found} = Alerts.acknowledge_alert(99999, user_id: user.id)
    end
  end

  describe "resolve_alert/2" do
    test "resolves an acknowledged alert", %{user: user} do
      alert = create_alert(%{title: "Test", status: "acknowledged"})

      assert {:ok, resolved_alert} = Alerts.resolve_alert(alert.id, user_id: user.id)
      assert resolved_alert.status == "resolved"
      assert resolved_alert.resolved_by_id == user.id
      assert resolved_alert.resolved_at != nil
    end

    test "can resolve a firing alert directly", %{user: user} do
      alert = create_alert(%{title: "Test", status: "firing"})

      assert {:ok, resolved_alert} = Alerts.resolve_alert(alert.id, user_id: user.id)
      assert resolved_alert.status == "resolved"
    end

    test "requires user_id" do
      alert = create_alert(%{title: "Test"})

      assert {:error, %Ecto.Changeset{} = changeset} = Alerts.resolve_alert(alert.id, [])
      assert %{resolved_by_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when alert not found", %{user: user} do
      assert {:error, :not_found} = Alerts.resolve_alert(99999, user_id: user.id)
    end
  end

  describe "update_alert/2" do
    test "updates alert with valid attributes" do
      alert = create_alert(%{title: "Original Title"})

      assert {:ok, updated_alert} = Alerts.update_alert(alert, %{title: "Updated Title"})
      assert updated_alert.title == "Updated Title"
    end

    test "returns error with invalid attributes" do
      alert = create_alert(%{title: "Test"})

      assert {:error, %Ecto.Changeset{}} = Alerts.update_alert(alert, %{severity: "invalid"})
    end
  end

  describe "delete_alert/1" do
    test "deletes the alert" do
      alert = create_alert(%{title: "To Delete"})

      assert {:ok, deleted_alert} = Alerts.delete_alert(alert)
      assert deleted_alert.id == alert.id
      assert {:error, :not_found} = Alerts.get_alert(alert.id)
    end
  end

  # Helper function to create alerts for testing
  defp create_alert(attrs) do
    default_attrs = %{
      title: "Test Alert",
      severity: "warning",
      source: "test",
      status: "firing",
      fired_at: DateTime.utc_now()
    }

    merged_attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    {:ok, alert} = Alerts.create_alert(merged_attrs)
    alert
  end
end
