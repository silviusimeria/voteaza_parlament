require "test_helper"

class CandidateNominationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate_nomination = candidate_nominations(:one)
  end

  test "should get index" do
    get candidate_nominations_url
    assert_response :success
  end

  test "should get new" do
    get new_candidate_nomination_url
    assert_response :success
  end

  test "should create candidate_nomination" do
    assert_difference("CandidateNomination.count") do
      post candidate_nominations_url, params: { candidate_nomination: { county_id: @candidate_nomination.county_id, kind: @candidate_nomination.kind, name: @candidate_nomination.name, party_id: @candidate_nomination.party_id, position: @candidate_nomination.position } }
    end

    assert_redirected_to candidate_nomination_url(CandidateNomination.last)
  end

  test "should show candidate_nomination" do
    get candidate_nomination_url(@candidate_nomination)
    assert_response :success
  end

  test "should get edit" do
    get edit_candidate_nomination_url(@candidate_nomination)
    assert_response :success
  end

  test "should update candidate_nomination" do
    patch candidate_nomination_url(@candidate_nomination), params: { candidate_nomination: { county_id: @candidate_nomination.county_id, kind: @candidate_nomination.kind, name: @candidate_nomination.name, party_id: @candidate_nomination.party_id, position: @candidate_nomination.position } }
    assert_redirected_to candidate_nomination_url(@candidate_nomination)
  end

  test "should destroy candidate_nomination" do
    assert_difference("CandidateNomination.count", -1) do
      delete candidate_nomination_url(@candidate_nomination)
    end

    assert_redirected_to candidate_nominations_url
  end
end
