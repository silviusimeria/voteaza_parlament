class Person < ApplicationRecord
  include Sluggable

  has_many :candidate_nominations
  has_many :people_links
  has_many :party_memberships
  has_many :counties, through: :candidate_nominations
  has_many :parties, through: :candidate_nominations

  has_many :connections
  has_many :connected_people, through: :connections

  has_many :inverse_connections, class_name: 'Connection', foreign_key: 'connected_person_id'
  has_many :inverse_connected_people, through: :inverse_connections, source: :person

  # Ransack config
  def self.ransackable_attributes(auth_object = nil)
    %w[id name funky_data slug created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations people_links counties parties party_memberships connections
connected_people inverse_connections inverse_connected_people]
  end

  def birth_date
    funky_data&.dig('birth_date')
  end

  def education_level
    funky_data&.dig('education_level')
  end

  def previous_role
    funky_data&.dig('position_type')
  end

  def valid_age?
    age = funky_data&.dig('age')
    age.present? && age.to_i > 18 && age.to_i < 100
  end

  def valid_birth_date?
    birth_date = funky_data&.dig('birth_date')
    birth_date.present? && !birth_date.include?("Nu a fost")
  end

  def valid_zodiac?
    zodiac = funky_data&.dig('zodiac')
    zodiac.present? && !zodiac.include?("Nu a fost")
  end

  def valid_education?
    education = funky_data&.dig('education_level')
    education.present? && !education.include?("Nu a fost") && education != "-"
  end

  def valid_last_job?
    job = funky_data&.dig('last_job')
    job.present? && !job.include?("Nu a fost") && job != "-"
  end

  def valid_prior_position?
    position = funky_data&.dig('prior_position')
    position.present? && !position.include?("Nu a fost") && position != "-"
  end

  def valid_prior_mandate?
    mandate = funky_data&.dig('prior_mandate')
    mandate.present? && !mandate.include?("Nu a fost") && mandate != "-"
  end

  def valid_prior_party?
    party = funky_data&.dig('prior_party')
    party.present? && !party.include?("Nu a fost") && party != "-"
  end

  def has_valid_political_experience?
    funky_data&.dig('had_prior_position') &&
      (valid_prior_position? || valid_prior_mandate? || valid_prior_party?)
  end

  def ad_library_link
    people_links.find_by(kind: 'ad_library')
  end

  def valid_ad_count?
    count = funky_data&.dig('ad_count')
    count.present? && count.to_i > 0
  end

  def has_social_media_activity?
    funky_data&.dig('paid_social_media') && (valid_ad_count? || ad_library_link.present?)
  end

  def corruption_cases?
    cases = funky_data&.dig('corruption_cases')
    cases.present? && cases != "Nu" && cases != "-"
  end

  # Link helpers
  def social_links
    people_links.social_media
  end

  def declaration_links
    people_links.declarations
  end

  def professional_links
    people_links.professional
  end

  def research_links
    people_links.research
  end

  def position_statements
    people_links.positions
  end
end