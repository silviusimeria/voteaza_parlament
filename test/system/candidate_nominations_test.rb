require "application_system_test_case"

class CandidateNominationsTest < ApplicationSystemTestCase
  setup do
    @candidate_nomination = candidate_nominations(:one)
  end

  test "visiting the index" do
    visit candidate_nominations_url
    assert_selector "h1", text: "Candidate nominations"
  end

  test "should create candidate nomination" do
    visit candidate_nominations_url
    click_on "New candidate nomination"

    fill_in "County", with: @candidate_nomination.county_id
    fill_in "Kind", with: @candidate_nomination.kind
    fill_in "Name", with: @candidate_nomination.name
    fill_in "Party", with: @candidate_nomination.party_id
    fill_in "Position", with: @candidate_nomination.position
    click_on "Create Candidate nomination"

    assert_text "Candidate nomination was successfully created"
    click_on "Back"
  end

  test "should update Candidate nomination" do
    visit candidate_nomination_url(@candidate_nomination)
    click_on "Edit this candidate nomination", match: :first

    fill_in "County", with: @candidate_nomination.county_id
    fill_in "Kind", with: @candidate_nomination.kind
    fill_in "Name", with: @candidate_nomination.name
    fill_in "Party", with: @candidate_nomination.party_id
    fill_in "Position", with: @candidate_nomination.position
    click_on "Update Candidate nomination"

    assert_text "Candidate nomination was successfully updated"
    click_on "Back"
  end

  test "should destroy Candidate nomination" do
    visit candidate_nomination_url(@candidate_nomination)
    click_on "Destroy this candidate nomination", match: :first

    assert_text "Candidate nomination was successfully destroyed"
  end
end
