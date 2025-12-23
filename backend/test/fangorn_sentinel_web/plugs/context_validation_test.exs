defmodule FangornSentinelWeb.ContextValidationTest do
  @moduledoc """
  Validation tests for JWT context plug.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinelWeb.ConnCase
  import Plug.Conn

  alias FangornSentinelWeb.Context
  alias FangornSentinel.Guardian

  describe "JWT token handling" do
    setup do
      {:ok, user} = FangornSentinel.Accounts.create_user(%{
        email: "context_test@example.com",
        password: "password123"
      })
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      %{user: user, token: token}
    end

    # FAILURES FOUND: 0
    test "handles malformed Bearer token gracefully" do
      conn = build_conn()
        |> put_req_header("authorization", "Bearer !")  # Invalid JWT
        |> Context.call([])

      # Should not crash, just set empty context
      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end

    # FAILURES FOUND: 0
    test "handles null bytes in token" do
      conn = build_conn()
        |> put_req_header("authorization", "Bearer abc\u0000def")
        |> Context.call([])

      # Should not crash
      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end

    # FAILURES FOUND: 0
    test "handles extremely long token (DoS protection)" do
      # 1MB fake token
      huge_token = String.duplicate("A", 1_000_000)

      conn = build_conn()
        |> put_req_header("authorization", "Bearer #{huge_token}")
        |> Context.call([])

      # Should not crash or take too long
      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end

    # FAILURES FOUND: 0
    test "handles missing Bearer prefix" do
      conn = build_conn()
        |> put_req_header("authorization", "just-a-token")
        |> Context.call([])

      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end

    # FAILURES FOUND: 0
    test "handles token for deleted user", %{token: token, user: user} do
      # Delete the user
      FangornSentinel.Repo.delete(user)

      conn = build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> Context.call([])

      # Should gracefully handle missing user
      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end

    # FAILURES FOUND: 0
    test "handles token with tampered claims" do
      # Try to decode valid structure but with tampered payload
      fake_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI5OTk5OTk5OSIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoxODAwMDAwMDAwfQ.fake_signature"

      conn = build_conn()
        |> put_req_header("authorization", "Bearer #{fake_token}")
        |> Context.call([])

      # Should reject invalid signature
      context = conn.private[:absinthe][:context]
      refute Map.has_key?(context, :current_user)
    end
  end
end
