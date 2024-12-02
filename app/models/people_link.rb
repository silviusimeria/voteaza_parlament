class PeopleLink < ApplicationRecord
  belongs_to :person

  KINDS = %w[
    website facebook telegram wikipedia instagram tiktok
    press linkedin cv asset_declaration interests_declaration
    criminal_record declaration_assets declaration_interests
    position_statement ad_library other
  ].freeze

  validates :kind, inclusion: { in: KINDS }
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