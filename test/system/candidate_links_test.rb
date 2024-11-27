require "application_system_test_case"

class CandidateLinksTest < ApplicationSystemTestCase
  setup do
    @candidate_link = candidate_links(:one)
  end

  test "visiting the index" do
    visit candidate_links_url
    assert_selector "h1", text: "Candidate links"
  end

  test "should create candidate link" do
    visit candidate_links_url
    click_on "New candidate link"

    fill_in "Candidate nomination", with: @candidate_link.candidate_nomination_id
    fill_in "Kind", with: @candidate_link.kind
    fill_in "Url", with: @candidate_link.url
    click_on "Create Candidate link"

    assert_text "Candidate link was successfully created"
    click_on "Back"
  end

  test "should update Candidate link" do
    visit candidate_link_url(@candidate_link)
    click_on "Edit this candidate link", match: :first

    fill_in "Candidate nomination", with: @candidate_link.candidate_nomination_id
    fill_in "Kind", with: @candidate_link.kind
    fill_in "Url", with: @candidate_link.url
    click_on "Update Candidate link"

    assert_text "Candidate link was successfully updated"
    click_on "Back"
  end

  test "should destroy Candidate link" do
    visit candidate_link_url(@candidate_link)
    click_on "Destroy this candidate link", match: :first

    assert_text "Candidate link was successfully destroyed"
  end
end
