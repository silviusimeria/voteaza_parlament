class ParliamentaryMembership < ApplicationRecord
  belongs_to :parliamentary_group
  belongs_to :politician
  
  validates :start_date, presence: true
  validates :politician_id, uniqueness: { scope: [:parliamentary_group_id, :end_date], 
    message: "cannot be in the same group twice for overlapping periods" }
  
  validate :no_overlapping_memberships
  
  scope :active, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  
  private
  
  def no_overlapping_memberships
    overlapping = ParliamentaryMembership
      .where(politician_id: politician_id)
      .where.not(id: id)
      .where(
        '(start_date <= ? AND (end_date IS NULL OR end_date >= ?))',
        end_date || Float::INFINITY,
        start_date
      )
    
    if overlapping.exists?
      errors.add(:base, 'Overlapping membership period exists')
    end
  end
end