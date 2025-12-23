defmodule FangornSentinelWeb.DashboardComponentsTest do
  use FangornSentinelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias FangornSentinelWeb.DashboardComponents

  describe "status_badge/1" do
    test "renders firing badge" do
      assigns = %{status: :firing}
      html = rendered_to_string(~H"<DashboardComponents.status_badge status={@status} />")

      assert html =~ "badge-error"
      assert html =~ "Firing"
    end

    test "renders acknowledged badge" do
      assigns = %{status: :acknowledged}
      html = rendered_to_string(~H"<DashboardComponents.status_badge status={@status} />")

      assert html =~ "badge-warning"
      assert html =~ "Acknowledged"
    end

    test "renders resolved badge" do
      assigns = %{status: :resolved}
      html = rendered_to_string(~H"<DashboardComponents.status_badge status={@status} />")

      assert html =~ "badge-success"
      assert html =~ "Resolved"
    end
  end

  describe "severity_badge/1" do
    test "renders critical badge" do
      assigns = %{severity: :critical}
      html = rendered_to_string(~H"<DashboardComponents.severity_badge severity={@severity} />")

      assert html =~ "badge-error"
      assert html =~ "Critical"
    end

    test "renders warning badge" do
      assigns = %{severity: :warning}
      html = rendered_to_string(~H"<DashboardComponents.severity_badge severity={@severity} />")

      assert html =~ "badge-warning"
      assert html =~ "Warning"
    end

    test "renders info badge" do
      assigns = %{severity: :info}
      html = rendered_to_string(~H"<DashboardComponents.severity_badge severity={@severity} />")

      assert html =~ "badge-info"
      assert html =~ "Info"
    end
  end

  describe "stat_card/1" do
    test "renders stat card with title and value" do
      assigns = %{title: "Test Title", value: 42, description: nil, icon: nil, class: nil}
      html = rendered_to_string(~H"<DashboardComponents.stat_card title={@title} value={@value} />")

      assert html =~ "Test Title"
      assert html =~ "42"
      assert html =~ "stat"
    end

    test "renders stat card with description" do
      assigns = %{}
      html = rendered_to_string(~H"""
        <DashboardComponents.stat_card title="Title" value={10} description="Some description" />
      """)

      assert html =~ "Some description"
    end

    test "renders stat card with icon" do
      assigns = %{}
      html = rendered_to_string(~H"""
        <DashboardComponents.stat_card title="Title" value={5} icon="hero-fire" />
      """)

      assert html =~ "hero-fire"
    end
  end

  describe "nav_link/1" do
    test "renders active link" do
      assigns = %{path: "/alerts", current_path: "/alerts", icon: "hero-bell"}
      html = rendered_to_string(~H"""
        <DashboardComponents.nav_link path={@path} current_path={@current_path} icon={@icon}>
          Alerts
        </DashboardComponents.nav_link>
      """)

      assert html =~ "active"
      assert html =~ "Alerts"
      assert html =~ "hero-bell"
    end

    test "renders inactive link" do
      assigns = %{path: "/alerts", current_path: "/", icon: "hero-bell"}
      html = rendered_to_string(~H"""
        <DashboardComponents.nav_link path={@path} current_path={@current_path} icon={@icon}>
          Alerts
        </DashboardComponents.nav_link>
      """)

      refute html =~ "active"
      assert html =~ "Alerts"
    end
  end
end
