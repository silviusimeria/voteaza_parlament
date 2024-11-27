class CandidateLink < ApplicationRecord
  belongs_to :candidate_nomination

  validates :url, :kind, presence: true

  enum :kind, {
    facebook: "facebook",
    twitter: "twitter",
    wikipedia: "wikipedia"
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[id candidate_nomination_id url kind created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nomination]
  end
end
