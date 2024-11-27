require "application_system_test_case"

class CountiesTest < ApplicationSystemTestCase
  setup do
    @county = counties(:one)
  end

  test "visiting the index" do
    visit counties_url
    assert_selector "h1", text: "Counties"
  end

  test "should create county" do
    visit counties_url
    click_on "New county"

    fill_in "Code", with: @county.code
    fill_in "Geojson", with: @county.geojson_id
    fill_in "Name", with: @county.name
    click_on "Create County"

    assert_text "County was successfully created"
    click_on "Back"
  end

  test "should update County" do
    visit county_url(@county)
    click_on "Edit this county", match: :first

    fill_in "Code", with: @county.code
    fill_in "Geojson", with: @county.geojson_id
    fill_in "Name", with: @county.name
    click_on "Update County"

    assert_text "County was successfully updated"
    click_on "Back"
  end

  test "should destroy County" do
    visit county_url(@county)
    click_on "Destroy this county", match: :first

    assert_text "County was successfully destroyed"
  end
end
