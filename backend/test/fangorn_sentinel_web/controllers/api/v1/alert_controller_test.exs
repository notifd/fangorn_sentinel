defmodule FangornSentinelWeb.API.V1.AlertControllerTest do
  use FangornSentinelWeb.ConnCase

  alias FangornSentinel.Alerts.Alert

  describe "POST /api/v1/alerts" do
    test "creates alert with valid data", %{conn: conn} do
      alert_params = %{
        "alert" => %{
          "title" => "Test Alert",
          "severity" => "critical",
          "source" => "test",
          "message" => "Test message"
        }
      }

      conn = post(conn, ~p"/api/v1/alerts", alert_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["title"] == "Test Alert"
      assert data["severity"] == "critical"
      assert data["source"] == "test"
      assert data["status"] == "firing"
    end

    test "returns error with missing alert param", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/alerts", %{})

      assert %{"error" => _} = json_response(conn, 400)
    end

    test "returns error with invalid data", %{conn: conn} do
      alert_params = %{
        "alert" => %{
          "title" => "",
          "severity" => "invalid"
        }
      }

      conn = post(conn, ~p"/api/v1/alerts", alert_params)

      assert %{"errors" => _} = json_response(conn, 422)
    end
  end

  describe "GET /api/v1/alerts (authenticated)" do
    test "returns 401 without authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/alerts")
      assert json_response(conn, 401)["error"] =~ "Authentication"
    end
  end

  describe "AlertJSON" do
    alias FangornSentinelWeb.API.V1.AlertJSON

    test "index/1 renders list of alerts" do
      alerts = [
        %Alert{
          id: 1,
          title: "Test 1",
          message: "Message 1",
          severity: :critical,
          status: :firing,
          source: "test",
          source_id: "abc",
          labels: %{},
          annotations: %{},
          fired_at: DateTime.utc_now(),
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ]

      result = AlertJSON.index(%{alerts: alerts})

      assert %{data: [alert_data], meta: %{count: 1}} = result
      assert alert_data.id == 1
      assert alert_data.title == "Test 1"
    end

    test "show/1 renders single alert" do
      alert = %Alert{
        id: 1,
        title: "Test",
        message: "Message",
        severity: :warning,
        status: :acknowledged,
        source: "test",
        source_id: nil,
        labels: %{"env" => "prod"},
        annotations: %{},
        fired_at: DateTime.utc_now(),
        acknowledged_at: DateTime.utc_now(),
        acknowledged_by_id: 1,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      result = AlertJSON.show(%{alert: alert})

      assert %{data: data} = result
      assert data.id == 1
      assert data.title == "Test"
      assert data.severity == :warning
      assert data.status == :acknowledged
      assert data.labels == %{"env" => "prod"}
    end
  end
end
