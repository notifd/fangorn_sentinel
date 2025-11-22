defmodule FangornSentinel.Alerts.AlertTest do
  use FangornSentinel.DataCase

  alias FangornSentinel.Alerts.Alert

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        title: "High CPU Usage",
        message: "CPU usage above 90%",
        severity: "critical",
        source: "grafana",
        fired_at: DateTime.utc_now()
      }

      changeset = Alert.changeset(%Alert{}, attrs)

      assert changeset.valid?
      assert changeset.changes.title == "High CPU Usage"
      assert changeset.changes.severity == "critical"
      assert Ecto.Changeset.get_field(changeset, :status) == "firing"
    end

    test "invalid changeset without required fields" do
      changeset = Alert.changeset(%Alert{}, %{})

      refute changeset.valid?
      assert %{title: ["can't be blank"]} = errors_on(changeset)
      assert %{severity: ["can't be blank"]} = errors_on(changeset)
      assert %{source: ["can't be blank"]} = errors_on(changeset)
      assert %{fired_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates severity is one of valid values" do
      changeset = Alert.changeset(%Alert{}, %{
        title: "Test",
        severity: "invalid",
        source: "test",
        fired_at: DateTime.utc_now()
      })

      refute changeset.valid?
      assert %{severity: ["is invalid"]} = errors_on(changeset)
    end

    test "validates status is one of valid values" do
      changeset = Alert.changeset(%Alert{}, %{
        title: "Test",
        severity: "warning",
        source: "test",
        status: "invalid_status",
        fired_at: DateTime.utc_now()
      })

      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid severity values" do
      for severity <- ["critical", "warning", "info"] do
        changeset = Alert.changeset(%Alert{}, %{
          title: "Test",
          severity: severity,
          source: "test",
          fired_at: DateTime.utc_now()
        })

        assert changeset.valid?
      end
    end

    test "accepts valid status values" do
      for status <- ["firing", "acknowledged", "resolved"] do
        changeset = Alert.changeset(%Alert{}, %{
          title: "Test",
          severity: "info",
          source: "test",
          status: status,
          fired_at: DateTime.utc_now()
        })

        assert changeset.valid?
      end
    end

    test "sets default values" do
      attrs = %{
        title: "Test Alert",
        severity: "warning",
        source: "grafana",
        fired_at: DateTime.utc_now()
      }

      changeset = Alert.changeset(%Alert{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "firing"
      assert Ecto.Changeset.get_field(changeset, :labels) == %{}
      assert Ecto.Changeset.get_field(changeset, :annotations) == %{}
    end

    test "accepts labels and annotations as maps" do
      attrs = %{
        title: "Test",
        severity: "critical",
        source: "prometheus",
        fired_at: DateTime.utc_now(),
        labels: %{"service" => "api", "environment" => "production"},
        annotations: %{"runbook" => "https://example.com/runbook"}
      }

      changeset = Alert.changeset(%Alert{}, attrs)

      assert changeset.valid?
      assert changeset.changes.labels == %{"service" => "api", "environment" => "production"}
      assert changeset.changes.annotations == %{"runbook" => "https://example.com/runbook"}
    end
  end

  describe "acknowledge_changeset/2" do
    test "sets acknowledged_at and acknowledged_by_id" do
      alert = %Alert{
        title: "Test",
        severity: "critical",
        source: "test",
        status: "firing",
        fired_at: DateTime.utc_now()
      }

      now = DateTime.utc_now()
      changeset = Alert.acknowledge_changeset(alert, %{acknowledged_by_id: 1})

      assert changeset.valid?
      assert changeset.changes.status == "acknowledged"
      assert changeset.changes.acknowledged_by_id == 1
      # acknowledged_at should be set to approximately now
      assert_in_delta DateTime.to_unix(changeset.changes.acknowledged_at),
                      DateTime.to_unix(now),
                      2
    end

    test "requires acknowledged_by_id" do
      alert = %Alert{status: "firing"}
      changeset = Alert.acknowledge_changeset(alert, %{})

      refute changeset.valid?
      assert %{acknowledged_by_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "resolve_changeset/2" do
    test "sets resolved_at and resolved_by_id" do
      alert = %Alert{
        title: "Test",
        severity: "critical",
        source: "test",
        status: "acknowledged",
        fired_at: DateTime.utc_now(),
        acknowledged_at: DateTime.utc_now()
      }

      now = DateTime.utc_now()
      changeset = Alert.resolve_changeset(alert, %{resolved_by_id: 1})

      assert changeset.valid?
      assert changeset.changes.status == "resolved"
      assert changeset.changes.resolved_by_id == 1
      # resolved_at should be set to approximately now
      assert_in_delta DateTime.to_unix(changeset.changes.resolved_at),
                      DateTime.to_unix(now),
                      2
    end

    test "requires resolved_by_id" do
      alert = %Alert{status: "acknowledged"}
      changeset = Alert.resolve_changeset(alert, %{})

      refute changeset.valid?
      assert %{resolved_by_id: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
