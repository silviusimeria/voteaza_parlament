class SenateMandate < ApplicationRecord
  belongs_to :election
  
  has_many :parliamentary_groups
  has_many :permanent_bureau_memberships
  has_many :senate_commissions

  validates :election, presence: true
  validates :slug, presence: true, uniqueness: true
  
  def self.current
    find_by(active: true)
  end
  
  def activate!
    SenateMandate.transaction do
      SenateMandate.where.not(id: id).update_all(active: false)
      update!(active: true)
    end
  end
end