defmodule FangornSentinelWeb.DashboardLiveTest do
  use FangornSentinelWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Dashboard LiveView" do
    test "renders dashboard page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Dashboard"
      assert html =~ "Overview of your on-call system"
      assert html =~ "Firing Alerts"
      assert html =~ "Acknowledged"
      assert html =~ "Resolved Today"
    end

    test "displays recent alerts section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Recent Alerts"
      assert html =~ "View All Alerts"
    end

    test "displays on-call section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "On-Call Now"
      assert html =~ "View Schedule"
    end

    test "displays quick actions", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Quick Actions"
      assert html =~ "View Alerts"
      assert html =~ "Manage Schedules"
      assert html =~ "Escalation Policies"
    end
  end

  describe "Navigation" do
    test "alerts page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/alerts")

      assert html =~ "Alerts"
      assert html =~ "Manage and respond to alerts"
    end

    test "schedules page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/schedules")

      assert html =~ "Schedules"
      assert html =~ "Manage on-call schedules"
    end

    test "escalations page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/escalations")

      assert html =~ "Escalation Policies"
      assert html =~ "Configure alert escalation"
    end

    test "teams page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/teams")

      assert html =~ "Teams"
      assert html =~ "Manage teams"
    end

    test "integrations page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/integrations")

      assert html =~ "Integrations"
      assert html =~ "Connect external services"
    end

    test "settings page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings")

      assert html =~ "Settings"
      assert html =~ "Configure your preferences"
    end
  end
end
