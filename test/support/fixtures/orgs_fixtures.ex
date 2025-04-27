defmodule RosterApp.OrgsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RosterApp.Orgs` context.
  """

  @doc """
  Generate a absences.
  """
  def absences_fixture(attrs \\ %{}) do
    {:ok, absences} =
      attrs
      |> Enum.into(%{
        unavailable_days: [1, 2]
      })
      |> RosterApp.Orgs.create_absences()

    absences
  end
end
