defmodule RosterApp.Repo do
  use Ecto.Repo,
    otp_app: :roster_app,
    adapter: Ecto.Adapters.Postgres
end
