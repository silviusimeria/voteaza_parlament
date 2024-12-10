class Person < ApplicationRecord
  include Sluggable

  has_many :candidate_nominations
  has_many :people_links
  has_many :party_memberships
  has_many :counties, through: :candidate_nominations
  has_many :parties, through: :candidate_nominations

  # Ransack config
  def self.ransackable_attributes(auth_object = nil)
    %w[id name funky_data slug created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations people_links counties parties party_memberships]
  end

  # JSON accessors for common funky data fields
  def birth_date
    funky_data['Data nașterii']
  end

  def education_level
    funky_data['Nivel de studii']
  end

  def previous_role
    funky_data['Ce funcție?']
  end

  def integrity_issues?
    funky_data['Cazuri de corupție'].present?
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