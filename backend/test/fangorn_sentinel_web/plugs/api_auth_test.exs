defmodule FangornSentinelWeb.Plugs.ApiAuthTest do
  use FangornSentinelWeb.ConnCase

  alias FangornSentinelWeb.Plugs.ApiAuth

  describe "API Key authentication" do
    setup do
      # Configure test API key
      Application.put_env(:fangorn_sentinel, :api_keys, [{"test_key", "test-secret-123"}])

      on_exit(fn ->
        Application.delete_env(:fangorn_sentinel, :api_keys)
      end)

      :ok
    end

    test "authenticates with valid API key", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-api-key", "test-secret-123")
        |> ApiAuth.call([])

      assert conn.assigns[:current_user] != nil
      assert conn.assigns[:current_user].name == "test_key"
      assert conn.assigns[:current_user].type == :api_key
      refute conn.halted
    end

    test "rejects invalid API key", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-api-key", "invalid-key")
        |> ApiAuth.call([])

      assert conn.halted
      assert conn.status == 401
    end

    test "rejects missing authentication when required", %{conn: conn} do
      conn = ApiAuth.call(conn, [])

      assert conn.halted
      assert conn.status == 401
    end

    test "continues without auth when not required", %{conn: conn} do
      conn = ApiAuth.call(conn, required: false)

      refute conn.halted
      assert conn.assigns[:current_user] == nil
    end
  end

  describe "init/1" do
    test "returns opts unchanged" do
      opts = [required: true]
      assert ApiAuth.init(opts) == opts
    end
  end
end
