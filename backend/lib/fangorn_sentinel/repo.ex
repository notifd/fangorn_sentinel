defmodule FangornSentinel.Repo do
  use Ecto.Repo,
    otp_app: :fangorn_sentinel,
    adapter: Ecto.Adapters.Postgres
end
