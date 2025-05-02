defmodule RosterApp.OrgsTest do
  use RosterApp.DataCase

  alias RosterApp.Orgs
  alias RosterApp.Tenants.Tenant
  alias RosterApp.Repo
  import RosterApp.AccountsFixtures

  describe "absences" do
    alias RosterApp.Orgs.Absences

    import RosterApp.OrgsFixtures

    test "list_absences/0 returns all absences" do
      absences = absences_fixture()
      assert Orgs.list_absences(1) == [absences]
    end

    test "get_absences!/1 returns the absences with given id" do
      absences = absences_fixture()
      assert Orgs.get_absences!(absences.id) == absences
    end

    test "create_absences/1 with valid data creates a absences" do
      valid_attrs = %{unavailable_days: [1, 2], user_id: 1}

      assert {:ok, %Absences{} = absences} = Orgs.create_absences(valid_attrs)
      assert absences.unavailable_days == [1, 2]

      assert [] == Orgs.list_absences(9999)
    end

    test "update_absences/2 with valid data updates the absences" do
      absences = absences_fixture()
      update_attrs = %{unavailable_days: [1]}

      assert {:ok, %Absences{} = absences} = Orgs.update_absences(absences, update_attrs)
      assert absences.unavailable_days == [1]
    end

    test "delete_absences/1 deletes the absences" do
      absences = absences_fixture()
      assert {:ok, %Absences{}} = Orgs.delete_absences(absences)
      assert_raise Ecto.NoResultsError, fn -> Orgs.get_absences!(absences.id) end
    end

    test "change_absences/1 returns a absences changeset" do
      absences = absences_fixture()
      assert %Ecto.Changeset{} = Orgs.change_absences(absences)
    end
  end

  # write tests for work types and departments belonging to multiple tenants making sure the data is not mixed up
  test "work types and departments belong to multiple tenants" do
    # Create a tenant with attrs
    tenant = Repo.insert!(%Tenant{name: "Test Tenant"})

    # Create a work type and department for the tenant
    {:ok, work_type} = work_type_fixture(tenant_id: tenant.id)
    {:ok, department} = department_fixture(tenant_id: tenant.id)

    # Create another tenant
    another_tenant = Repo.insert!(%Tenant{name: "other Tenant"})

    # Create a work type and department for the other tenant
    {:ok, another_work_type} = work_type_fixture(tenant_id: another_tenant.id)
    {:ok, another_department} = department_fixture(tenant_id: another_tenant.id)

    # assert list work types and departments for the tenant
    assert Orgs.list_work_types(tenant.id) == [work_type]
    assert Orgs.list_departments(tenant.id) == [department]
    # assert list work types and departments for the other tenant
    assert Orgs.list_work_types(another_tenant.id) == [another_work_type]
    assert Orgs.list_departments(another_tenant.id) == [another_department]
  end
end
