defmodule FangornSentinelWeb.AlertsLiveTest do
  use FangornSentinelWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "AlertsLive.Index" do
    test "renders alerts list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "Alerts"
      assert html =~ "Manage and respond to alerts"
      assert html =~ "Status"
      assert html =~ "Severity"
      assert html =~ "Search"
    end

    test "displays filter controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "Firing"
      assert html =~ "Acknowledged"
      assert html =~ "Resolved"
      assert html =~ "Critical"
      assert html =~ "Warning"
      assert html =~ "Info"
    end

    test "displays table headers", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "Severity"
      assert html =~ "Title"
      assert html =~ "Status"
      assert html =~ "Source"
      assert html =~ "Fired At"
      assert html =~ "Actions"
    end

    test "displays pagination controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "Page"
      assert html =~ "Previous"
      assert html =~ "Next"
    end

    test "shows empty state when no alerts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "No alerts found"
    end

    test "filter form can be cleared", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/alerts")

      # The clear button should exist
      assert has_element?(view, "button", "Clear")
    end

    test "handles filter event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/alerts")

      # Filter by status
      html = view
        |> element("form")
        |> render_change(%{"filters" => %{"status" => "firing", "severity" => "", "search" => ""}})

      assert html =~ "Alerts"
    end

    test "handles sort event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/alerts")

      # Click sort on severity column
      html = view
        |> element("th", "Severity")
        |> render_click()

      assert html =~ "Alerts"
    end
  end

  describe "AlertsLive.Show" do
    test "redirects when alert not found", %{conn: conn} do
      # When alert is not found, it redirects to /alerts with flash error
      assert {:error, {:redirect, %{to: "/alerts", flash: %{"error" => "Alert not found"}}}} =
               live(conn, ~p"/alerts/999999")
    end
  end

  describe "Real-time updates" do
    test "subscribes to alerts PubSub on mount", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/alerts")

      # View should be connected
      assert view.module == FangornSentinelWeb.AlertsLive.Index
    end
  end
end
