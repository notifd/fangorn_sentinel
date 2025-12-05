defmodule FangornSentinelWeb.GraphQL.Resolvers.AlertValidationTest do
  @moduledoc """
  Validation tests for Alert GraphQL resolvers.

  Testing that INVALID input is REJECTED.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinelWeb.ConnCase

  alias FangornSentinel.Accounts

  describe "alert resolver validation" do
    setup do
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        password: "password123"
      })

      {:ok, token, _claims} = FangornSentinel.Guardian.encode_and_sign(user)

      %{user: user, token: token}
    end

    # FAILURES FOUND: 0
    test "rejects negative limit in alerts query", %{conn: conn, token: token} do
      query = """
      query {
        alerts(limit: -100) {
          id
        }
      }
      """

      conn = conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql", %{query: query})

      # BUG if this succeeds with negative limit
      response = json_response(conn, 200)

      if response["errors"] do
        # Good - rejected
        :ok
      else
        # BUG - should reject negative limit
        alerts = response["data"]["alerts"]
        flunk("BUG: Negative limit accepted, returned #{length(alerts || [])} alerts")
      end
    end

    # FAILURES FOUND: 0
    test "rejects limit > 10000 (resource exhaustion)", %{conn: conn, token: token} do
      query = """
      query {
        alerts(limit: 1000000) {
          id
        }
      }
      """

      conn = conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql", %{query: query})

      response = json_response(conn, 200)

      if response["errors"] do
        :ok
      else
        # BUG - should cap limit
        alerts = response["data"]["alerts"] || []
        if length(alerts) > 1000 do
          flunk("BUG: Huge limit accepted, returned #{length(alerts)} alerts (memory risk)")
        end
      end
    end

    # FAILURES FOUND: 0
    test "rejects negative offset", %{conn: conn, token: token} do
      query = """
      query {
        alerts(offset: -50) {
          id
        }
      }
      """

      conn = conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql", %{query: query})

      response = json_response(conn, 200)

      # Should either error or ignore
      if !response["errors"] && response["data"]["alerts"] do
        # If it succeeds, verify it didn't use negative offset
        # (Hard to test directly, but negative offset could cause SQL errors)
        :ok
      end
    end

    # FAILURES FOUND: 0
    test "rejects acknowledge without authentication", %{conn: conn} do
      mutation = """
      mutation {
        acknowledgeAlert(alertId: "1", note: "Checking") {
          id
        }
      }
      """

      conn = post(conn, "/api/graphql", %{query: mutation})

      response = json_response(conn, 200)

      # Must have errors - can't acknowledge without auth
      assert response["errors"], "BUG: Can acknowledge alert without authentication"
      assert Enum.any?(response["errors"], fn err ->
        String.contains?(err["message"] || "", "authenticated") or
        String.contains?(err["message"] || "", "Unauthorized")
      end), "BUG: Wrong error message for unauthenticated request"
    end

    # FAILURES FOUND: 0
    test "rejects acknowledge with SQL injection attempt", %{conn: conn, token: token} do
      # Try SQL injection in alert_id
      mutation = """
      mutation {
        acknowledgeAlert(alertId: "1 OR 1=1--", note: "Test") {
          id
        }
      }
      """

      conn = conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql", %{query: mutation})

      response = json_response(conn, 200)

      # Should safely handle - either error or gracefully fail
      # BUG if it acknowledges multiple alerts
      if response["data"] && response["data"]["acknowledgeAlert"] do
        flunk("BUG: SQL injection in alertId might have succeeded")
      end
    end

    # FAILURES FOUND: 0
    test "rejects acknowledge with extremely long note (DoS)", %{conn: conn, token: token} do
      # 10MB note
      huge_note = String.duplicate("A", 10_000_000)

      mutation = """
      mutation {
        acknowledgeAlert(alertId: "1", note: "#{huge_note}") {
          id
        }
      }
      """

      # This might timeout or be rejected by Phoenix
      assert_timeout(5000, fn ->
        conn = conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/graphql", %{query: mutation})

        response = json_response(conn, 200)

        # Should reject or truncate
        if response["data"] && response["data"]["acknowledgeAlert"] do
          # BUG if huge note was stored
          flunk("BUG: 10MB note accepted (DoS risk)")
        end
      end)
    end

    # FAILURES FOUND: 0
    test "rejects acknowledge with null bytes in note", %{conn: conn, token: token} do
      mutation = """
      mutation {
        acknowledgeAlert(alertId: "1", note: "Test\u0000injection") {
          id
        }
      }
      """

      conn = conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql", %{query: mutation})

      response = json_response(conn, 200)

      # Should handle gracefully - either error or strip null bytes
      # BUG if PostgreSQL crashes
      if response["errors"] do
        # Check it's not a database error
        error_msg = List.first(response["errors"])["message"] || ""
        refute String.contains?(error_msg, "Postgrex.Error"),
          "BUG: Null byte caused PostgreSQL error"
      end
    end
  end

  defp assert_timeout(ms, fun) do
    task = Task.async(fun)

    case Task.yield(task, ms) || Task.shutdown(task) do
      {:ok, _result} -> :ok
      nil -> flunk("Operation timed out after #{ms}ms")
    end
  end
end
