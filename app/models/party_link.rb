class PartyLink < ApplicationRecord
  belongs_to :party

  validates :url, :kind, presence: true

  enum :kind, {
    website: "website",
    facebook: "facebook",
    twitter: "twitter"
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[id party_id url kind created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[party]
  end
end
