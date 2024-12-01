class PopulateExistingSlugs < ActiveRecord::Migration[8.0]
  def up
    [Party, CandidateNomination, County].each do |model|
      model.find_each do |record|
        record.send(:set_slug)
        record.save!(validate: false)
      end
    end
  end

  def down
    # No need to remove slugs as they'll be dropped with the previous migration
  end
end
