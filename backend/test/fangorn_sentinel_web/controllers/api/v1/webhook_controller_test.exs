defmodule FangornSentinelWeb.API.V1.WebhookControllerTest do
  use FangornSentinelWeb.ConnCase

  alias FangornSentinel.Alerts

  describe "POST /api/v1/webhooks/grafana" do
    test "creates alerts from Grafana webhook payload", %{conn: conn} do
      payload = %{
        "receiver" => "fangorn-sentinel",
        "status" => "firing",
        "alerts" => [
          %{
            "status" => "firing",
            "labels" => %{
              "alertname" => "HighCPUUsage",
              "severity" => "critical",
              "instance" => "server-01",
              "job" => "node-exporter"
            },
            "annotations" => %{
              "summary" => "CPU usage is above 90%",
              "description" => "CPU usage on server-01 has been above 90% for 5 minutes",
              "runbook_url" => "https://wiki.example.com/runbooks/high-cpu"
            },
            "startsAt" => "2025-11-22T00:00:00Z",
            "endsAt" => "0001-01-01T00:00:00Z",
            "generatorURL" => "https://grafana.example.com/alerting/123",
            "fingerprint" => "abc123def456"
          }
        ],
        "groupLabels" => %{},
        "commonLabels" => %{
          "alertname" => "HighCPUUsage"
        },
        "commonAnnotations" => %{},
        "externalURL" => "https://grafana.example.com",
        "version" => "4",
        "groupKey" => "{}:{}"
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "received" => 1
             }

      # Verify alert was created
      alerts = Alerts.list_alerts()
      assert length(alerts) == 1

      alert = hd(alerts)
      assert alert.title == "HighCPUUsage"
      assert alert.message == "CPU usage is above 90%"
      assert alert.severity == "critical"
      assert alert.source == "grafana"
      assert alert.source_id == "abc123def456"
      assert alert.status == "firing"
      assert alert.labels["instance"] == "server-01"
      assert alert.annotations["runbook_url"] == "https://wiki.example.com/runbooks/high-cpu"
    end

    test "creates multiple alerts from single webhook", %{conn: conn} do
      payload = %{
        "alerts" => [
          %{
            "labels" => %{
              "alertname" => "Alert1",
              "severity" => "warning"
            },
            "annotations" => %{"summary" => "First alert"},
            "startsAt" => "2025-11-22T00:00:00Z",
            "fingerprint" => "fp1"
          },
          %{
            "labels" => %{
              "alertname" => "Alert2",
              "severity" => "critical"
            },
            "annotations" => %{"summary" => "Second alert"},
            "startsAt" => "2025-11-22T00:01:00Z",
            "fingerprint" => "fp2"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "received" => 2
             }

      alerts = Alerts.list_alerts()
      assert length(alerts) == 2
    end

    test "maps Grafana severity to our severity levels", %{conn: conn} do
      severities = [
        {"critical", "critical"},
        {"warning", "warning"},
        {"page", "critical"},
        {"info", "info"},
        {"unknown", "info"}
      ]

      for {grafana_severity, expected_severity} <- severities do
        payload = %{
          "alerts" => [
            %{
              "labels" => %{
                "alertname" => "Test-#{grafana_severity}",
                "severity" => grafana_severity
              },
              "annotations" => %{"summary" => "Test #{grafana_severity}"},
              "startsAt" => "2025-11-22T00:00:00Z",
              "fingerprint" => "test-#{grafana_severity}"
            }
          ]
        }

        post(conn, ~p"/api/v1/webhooks/grafana", payload)

        # Find the specific alert we just created by title
        alerts = Alerts.list_alerts()
        alert = Enum.find(alerts, fn a -> a.title == "Test-#{grafana_severity}" end)
        assert alert.severity == expected_severity, "Expected #{grafana_severity} to map to #{expected_severity}"
      end
    end

    test "uses description as message if summary not available", %{conn: conn} do
      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "Test", "severity" => "info"},
            "annotations" => %{"description" => "This is the description"},
            "startsAt" => "2025-11-22T00:00:00Z",
            "fingerprint" => "test"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      assert json_response(conn, 200)["status"] == "ok"

      alert = Alerts.list_alerts() |> hd()
      assert alert.message == "This is the description"
    end

    test "handles alerts without annotations", %{conn: conn} do
      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "MinimalAlert", "severity" => "info"},
            "startsAt" => "2025-11-22T00:00:00Z",
            "fingerprint" => "minimal"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      assert json_response(conn, 200)["status"] == "ok"

      alert = Alerts.list_alerts() |> hd()
      assert alert.title == "MinimalAlert"
      assert alert.message == nil
      assert alert.annotations == %{}
    end

    test "returns 400 for invalid payload", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/webhooks/grafana", %{"invalid" => "data"})

      assert json_response(conn, 400) == %{
               "error" => "Invalid webhook payload"
             }
    end

    test "handles empty alerts array", %{conn: conn} do
      payload = %{"alerts" => []}

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "received" => 0
             }
    end

    test "deduplicates alerts by fingerprint", %{conn: conn} do
      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "DuplicateTest", "severity" => "warning"},
            "annotations" => %{"summary" => "Original"},
            "startsAt" => "2025-11-22T00:00:00Z",
            "fingerprint" => "duplicate-fp"
          }
        ]
      }

      # Send first webhook
      post(conn, ~p"/api/v1/webhooks/grafana", payload)
      assert length(Alerts.list_alerts()) == 1

      # Send duplicate with updated message
      updated_payload = put_in(payload, ["alerts", Access.at(0), "annotations", "summary"], "Updated")
      post(conn, ~p"/api/v1/webhooks/grafana", updated_payload)

      # Should still have only 1 alert, but updated
      alerts = Alerts.list_alerts()
      assert length(alerts) == 1
      alert = hd(alerts)
      assert alert.message == "Updated"
    end
  end
end
