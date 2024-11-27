class CandidateLink < ApplicationRecord
  belongs_to :candidate_nomination

  validates :url, :kind, presence: true

  enum :kind, {
    website: "website",
    facebook: "facebook",
    telegram: "telegram",
    wikipedia: "wikipedia",
    instagram: "instagram",
    tiktok: "tiktok"
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[id candidate_nomination_id url kind created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nomination]
  end
end
