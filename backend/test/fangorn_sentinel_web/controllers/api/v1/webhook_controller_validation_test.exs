defmodule FangornSentinelWeb.API.V1.WebhookControllerValidationTest do
  @moduledoc """
  Validation tests for webhook controller - testing that INVALID input is REJECTED.

  Following huorn testing methodology:
  - Tests must use real data or realistic attack vectors
  - Tests must be able to actually fail (find real bugs)
  - Track failures found for each test
  - Delete tests that don't find bugs

  FAILURES FOUND: 6 (86% hit rate - 6 out of 7 tests found bugs)
  """
  use FangornSentinelWeb.ConnCase

  alias FangornSentinel.Alerts

  describe "grafana webhook validation" do
    # FAILURES FOUND: 1 (Bug #1: DoS via unlimited alerts)
    test "rejects webhook with 1000+ alerts (DoS protection)", %{conn: conn} do
      # Real attack vector: Flood system with thousands of alerts
      large_payload = %{
        "alerts" => Enum.map(1..1000, fn i ->
          %{
            "labels" => %{"alertname" => "Alert#{i}"},
            "fingerprint" => "fp#{i}"
          }
        end)
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", large_payload)

      # BUG if this returns 200 OK - should reject large payloads
      assert conn.status in [400, 413], "Should reject large alert payloads (got #{conn.status})"
    end

    # FAILURES FOUND: 1 (Bug #2: DoS via huge strings)
    test "rejects alerts with extremely long titles (resource exhaustion)", %{conn: conn} do
      # Real attack: 10MB title string
      huge_title = String.duplicate("A", 10_000_000)

      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => huge_title},
            "fingerprint" => "test123"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      # BUG if this succeeds - should reject huge fields
      assert conn.status in [400, 413], "Should reject huge alert titles (got #{conn.status})"
    end

    # FAILURES FOUND: 1 (Bug #3: Null bytes crash PostgreSQL)
    test "rejects alerts with labels containing null bytes", %{conn: conn} do
      # Security: Null bytes can cause injection attacks
      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "Test\u0000injection"},
            "fingerprint" => "test123"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      # BUG if this succeeds - should sanitize or reject
      if conn.status == 200 do
        # Check if null byte was stored
        alerts = Alerts.list_alerts()
        alert = Enum.find(alerts, &(&1.source_id == "test123"))

        if alert && String.contains?(alert.title, <<0>>) do
          flunk("SECURITY BUG: Null byte stored in alert title")
        end
      end
    end

    # FAILURES FOUND: 1 (Bug #5: Timestamps 100 years old)
    test "rejects alerts with timestamp 100 years in the past", %{conn: conn} do
      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "OldAlert"},
            "annotations" => %{"summary" => "Ancient alert"},
            "startsAt" => "1925-01-01T00:00:00Z",
            "fingerprint" => "ancient"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      # BUG if this succeeds - timestamps should be reasonable
      if conn.status == 200 do
        alerts = Alerts.list_alerts()
        alert = Enum.find(alerts, &(&1.source_id == "ancient"))

        if alert do
          diff_days = Date.diff(Date.utc_today(), DateTime.to_date(alert.fired_at))
          assert diff_days < 365, "BUG: Alert from #{diff_days} days ago accepted (should reject old timestamps)"
        end
      end
    end

    # FAILURES FOUND: 1 (Bug #6: Timestamps 10 years in future)
    test "rejects alerts with timestamp 10 years in future", %{conn: conn} do
      future_date = DateTime.utc_now() |> DateTime.add(10 * 365 * 24 * 60 * 60, :second) |> DateTime.to_iso8601()

      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "FutureAlert"},
            "startsAt" => future_date,
            "fingerprint" => "future"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      if conn.status == 200 do
        alerts = Alerts.list_alerts()
        alert = Enum.find(alerts, &(&1.source_id == "future"))

        if alert do
          diff_days = Date.diff(DateTime.to_date(alert.fired_at), Date.utc_today())
          assert diff_days < 1, "BUG: Alert from #{diff_days} days in future accepted"
        end
      end
    end

    # FAILURES FOUND: 1 (Bug #4: Type confusion crash)
    test "handles labels as string instead of map (type confusion)", %{conn: conn} do
      # Real scenario: Misconfigured Grafana sends wrong types
      payload = %{
        "alerts" => [
          %{
            "labels" => "not-a-map",  # Type confusion
            "fingerprint" => "typetest"
          }
        ]
      }

      conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)

      # Should either reject or handle gracefully
      if conn.status == 200 do
        alerts = Alerts.list_alerts()
        alert = Enum.find(alerts, &(&1.source_id == "typetest"))

        if alert do
          # BUG if labels isn't a map
          assert is_map(alert.labels), "BUG: Labels stored as non-map: #{inspect(alert.labels)}"
        end
      end
    end

    # FAILURES FOUND: 0 (Test passed - deep nesting handled OK)
    test "handles deeply nested JSON in annotations (DoS via nesting)", %{conn: conn} do
      # Build 100-level deep nested structure
      deep_json = Enum.reduce(1..100, %{"end" => true}, fn i, acc ->
        %{"level#{i}" => acc}
      end)

      payload = %{
        "alerts" => [
          %{
            "labels" => %{"alertname" => "Deep"},
            "annotations" => deep_json,
            "fingerprint" => "deep"
          }
        ]
      }

      # Should handle without crashing or consuming excessive memory
      assert_timeout(5000, fn ->
        conn = post(conn, ~p"/api/v1/webhooks/grafana", payload)
        # BUG if this times out or crashes
        assert conn.status in [200, 400]
      end)
    end
  end

  # Helper to assert operation completes within timeout
  defp assert_timeout(ms, fun) do
    task = Task.async(fun)

    case Task.yield(task, ms) || Task.shutdown(task) do
      {:ok, _result} -> :ok
      nil -> flunk("Operation timed out after #{ms}ms")
    end
  end
end
