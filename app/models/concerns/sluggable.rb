module Sluggable
  extend ActiveSupport::Concern

  included do
    before_save :set_slug
  end

  private

  def set_slug
    self.slug = name.downcase
                    .gsub('ș', 's').gsub('ț', 't') # Handle Romanian special cases first
                    .gsub('ă', 'a').gsub('â', 'a').gsub('î', 'i')
                    .gsub(/[^a-z0-9\s-]/, '') # remove non-alphanumeric except spaces and hyphens
                    .gsub(/\s+/, '-')         # replace spaces with hyphens
                    .gsub(/-+/, '-')          # collapse multiple hyphens
                    .gsub(/^-|-$/, '')        # trim hyphens from ends
  end
end