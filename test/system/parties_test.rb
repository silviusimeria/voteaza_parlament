require "application_system_test_case"

class PartiesTest < ApplicationSystemTestCase
  setup do
    @party = parties(:one)
  end

  test "visiting the index" do
    visit parties_url
    assert_selector "h1", text: "Parties"
  end

  test "should create party" do
    visit parties_url
    click_on "New party"

    fill_in "Color", with: @party.color
    fill_in "Logo url", with: @party.logo_url
    fill_in "Name", with: @party.name
    click_on "Create Party"

    assert_text "Party was successfully created"
    click_on "Back"
  end

  test "should update Party" do
    visit party_url(@party)
    click_on "Edit this party", match: :first

    fill_in "Color", with: @party.color
    fill_in "Logo url", with: @party.logo_url
    fill_in "Name", with: @party.name
    click_on "Update Party"

    assert_text "Party was successfully updated"
    click_on "Back"
  end

  test "should destroy Party" do
    visit party_url(@party)
    click_on "Destroy this party", match: :first

    assert_text "Party was successfully destroyed"
  end
end
