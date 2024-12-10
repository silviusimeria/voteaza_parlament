class PeopleLink < ApplicationRecord
  belongs_to :person

  enum :kind, {
    website: "website",
    facebook: "facebook",
    telegram: "telegram",
    wikipedia: "wikipedia",
    instagram: "instagram",
    tiktok: "tiktok",
    press: "press",
    linkedin: "linkedin",
    cv: "cv",
    asset_declaration: "asset_declaration",
    interests_declaration: "interests_declaration",
    criminal_record: "criminal_record",
    declaration_assets: "declaration_assets",
    declaration_interests: "declaration_interests",
    position_statement: "position_statement",
    ad_library: "ad_library",
    other: "other"
  }

  validates :url, presence: true

  # Ransack config
  def self.ransackable_attributes(auth_object = nil)
    %w[id kind url official person_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[person]
  end

  # Helper scopes for common groupings
  scope :social_media, -> { where(kind: %w[facebook instagram tiktok telegram]) }
  scope :declarations, -> { where(kind: %w[asset_declaration interests_declaration declaration_assets declaration_interests criminal_record]) }
  scope :professional, -> { where(kind: %w[linkedin cv website]) }
  scope :research, -> { where(kind: %w[wikipedia press ad_library]) }
  scope :positions, -> { where(kind: 'position_statement') }
end