defmodule RosterApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RosterApp.Accounts` context.
  """

  alias RosterApp.Repo

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      tenant_id: 1
    })
  end

  def user_fixture(attrs \\ %{}) do
    tenant = Repo.insert!(%RosterApp.Tenants.Tenant{name: "Test-Tenant"})

    {:ok, user} =
      attrs
      |> Enum.into(%{tenant_id: tenant.id})
      |> valid_user_attributes()
      |> RosterApp.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  alias RosterApp.Orgs

  def work_type_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      name: "Cleaning"
    })
    |> Orgs.create_work_type()
  end

  def department_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      name: "Maintenance"
    })
    |> Orgs.create_department()
  end
end
