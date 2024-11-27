require "application_system_test_case"

class PartyLinksTest < ApplicationSystemTestCase
  setup do
    @party_link = party_links(:one)
  end

  test "visiting the index" do
    visit party_links_url
    assert_selector "h1", text: "Party links"
  end

  test "should create party link" do
    visit party_links_url
    click_on "New party link"

    fill_in "Kind", with: @party_link.kind
    fill_in "Party", with: @party_link.party_id
    fill_in "Url", with: @party_link.url
    click_on "Create Party link"

    assert_text "Party link was successfully created"
    click_on "Back"
  end

  test "should update Party link" do
    visit party_link_url(@party_link)
    click_on "Edit this party link", match: :first

    fill_in "Kind", with: @party_link.kind
    fill_in "Party", with: @party_link.party_id
    fill_in "Url", with: @party_link.url
    click_on "Update Party link"

    assert_text "Party link was successfully updated"
    click_on "Back"
  end

  test "should destroy Party link" do
    visit party_link_url(@party_link)
    click_on "Destroy this party link", match: :first

    assert_text "Party link was successfully destroyed"
  end
end
