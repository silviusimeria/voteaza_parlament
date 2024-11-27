require "test_helper"

class CandidateLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate_link = candidate_links(:one)
  end

  test "should get index" do
    get candidate_links_url
    assert_response :success
  end

  test "should get new" do
    get new_candidate_link_url
    assert_response :success
  end

  test "should create candidate_link" do
    assert_difference("CandidateLink.count") do
      post candidate_links_url, params: { candidate_link: { candidate_nomination_id: @candidate_link.candidate_nomination_id, kind: @candidate_link.kind, url: @candidate_link.url } }
    end

    assert_redirected_to candidate_link_url(CandidateLink.last)
  end

  test "should show candidate_link" do
    get candidate_link_url(@candidate_link)
    assert_response :success
  end

  test "should get edit" do
    get edit_candidate_link_url(@candidate_link)
    assert_response :success
  end

  test "should update candidate_link" do
    patch candidate_link_url(@candidate_link), params: { candidate_link: { candidate_nomination_id: @candidate_link.candidate_nomination_id, kind: @candidate_link.kind, url: @candidate_link.url } }
    assert_redirected_to candidate_link_url(@candidate_link)
  end

  test "should destroy candidate_link" do
    assert_difference("CandidateLink.count", -1) do
      delete candidate_link_url(@candidate_link)
    end

    assert_redirected_to candidate_links_url
  end
end
