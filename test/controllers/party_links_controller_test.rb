require "test_helper"

class PartyLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @party_link = party_links(:one)
  end

  test "should get index" do
    get party_links_url
    assert_response :success
  end

  test "should get new" do
    get new_party_link_url
    assert_response :success
  end

  test "should create party_link" do
    assert_difference("PartyLink.count") do
      post party_links_url, params: { party_link: { kind: @party_link.kind, party_id: @party_link.party_id, url: @party_link.url } }
    end

    assert_redirected_to party_link_url(PartyLink.last)
  end

  test "should show party_link" do
    get party_link_url(@party_link)
    assert_response :success
  end

  test "should get edit" do
    get edit_party_link_url(@party_link)
    assert_response :success
  end

  test "should update party_link" do
    patch party_link_url(@party_link), params: { party_link: { kind: @party_link.kind, party_id: @party_link.party_id, url: @party_link.url } }
    assert_redirected_to party_link_url(@party_link)
  end

  test "should destroy party_link" do
    assert_difference("PartyLink.count", -1) do
      delete party_link_url(@party_link)
    end

    assert_redirected_to party_links_url
  end
end
