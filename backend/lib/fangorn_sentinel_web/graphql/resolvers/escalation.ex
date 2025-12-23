defmodule FangornSentinelWeb.GraphQL.Resolvers.Escalation do
  @moduledoc """
  GraphQL resolver for escalation policies.
  """

  alias FangornSentinel.Escalation

  # Queries

  def list_policies(_parent, _args, %{context: %{current_user: _user}}) do
    {:ok, Escalation.list_policies()}
  end

  def list_policies(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def get_policy(_parent, %{id: id}, %{context: %{current_user: _user}}) do
    case Escalation.get_policy_with_steps!(id) do
      nil -> {:error, "Policy not found"}
      policy -> {:ok, policy}
    end
  rescue
    Ecto.NoResultsError -> {:error, "Policy not found"}
  end

  def get_policy(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  # Mutations

  def create_policy(_parent, %{input: input}, %{context: %{current_user: _user}}) do
    case Escalation.create_policy(input) do
      {:ok, policy} -> {:ok, policy}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def create_policy(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def update_policy(_parent, %{id: id, input: input}, %{context: %{current_user: _user}}) do
    policy = Escalation.get_policy!(id)

    case Escalation.update_policy(policy, input) do
      {:ok, policy} -> {:ok, policy}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  rescue
    Ecto.NoResultsError -> {:error, "Policy not found"}
  end

  def update_policy(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def delete_policy(_parent, %{id: id}, %{context: %{current_user: _user}}) do
    policy = Escalation.get_policy!(id)

    case Escalation.delete_policy(policy) do
      {:ok, _} -> {:ok, true}
      {:error, _} -> {:error, "Failed to delete policy"}
    end
  rescue
    Ecto.NoResultsError -> {:error, "Policy not found"}
  end

  def delete_policy(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def add_step(_parent, %{policy_id: policy_id, input: input}, %{context: %{current_user: _user}}) do
    attrs = Map.put(input, :policy_id, policy_id)

    case Escalation.create_step(attrs) do
      {:ok, step} -> {:ok, step}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def add_step(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  # Helpers

  defp format_errors(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    "Validation failed: #{inspect(errors)}"
  end
end
