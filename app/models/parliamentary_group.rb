class ParliamentaryGroup < ApplicationRecord
  has_many :parliamentary_group_memberships
  has_many :politicians, through: :parliamentary_group_memberships

  belongs_to :party
  belongs_to :senate_mandate

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", Date.current, Date.current) }

  def self.for_mandate(mandate)
    where(senate_mandate: mandate)
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "name", "official_id", "party_id", "senate_mandate_id", "short_name", "slug", "updated_at" ]
  end
end
