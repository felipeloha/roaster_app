defmodule RosterApp.OrgsTest do
  use RosterApp.DataCase

  alias RosterApp.Orgs

  describe "absences" do
    alias RosterApp.Orgs.Absences

    import RosterApp.OrgsFixtures

    test "list_absences/0 returns all absences" do
      absences = absences_fixture()
      assert Orgs.list_absences() == [absences]
    end

    test "get_absences!/1 returns the absences with given id" do
      absences = absences_fixture()
      assert Orgs.get_absences!(absences.id) == absences
    end

    test "create_absences/1 with valid data creates a absences" do
      valid_attrs = %{unavailable_days: [1, 2]}

      assert {:ok, %Absences{} = absences} = Orgs.create_absences(valid_attrs)
      assert absences.unavailable_days == [1, 2]
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
end
