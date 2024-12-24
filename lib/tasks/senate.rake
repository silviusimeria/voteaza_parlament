namespace :senate do
  desc "Update senators data with DOB and parliament IDs"

  task update: :environment do
    puts "Starting senators data update..."
    Senate::UpdateSenatorsData.new.call
    puts "Update complete!"
  end

  desc "Seed senate structure (mandate, groups, commissions) from JSON"
  task seed_structure: :environment do
    Senate::StructureSeeder.new.call
  end

  desc "Check for mismatches between qualified senate nominees and parliament IDs"
  task check_parliament_ids: :environment do
    Senate::ParliamentIdChecker.new.call
  end

  desc "Mark candidate nomination mandates based on parliament IDs presnce for senate"
  task :update_mandates do
    Person.where.not(parliament_id: nil).each do |p|
      p.candidate_nominations.first.update(mandate_allocated: true,
                                           mandate_started: true,
                                           mandate_start_date: Date.today)
    end
  end

  desc "Assign qualified senators to parliamentary groups"
  task assign_to_groups: :environment do
    Senate::MembershipAssigner.new.call
  end

  desc "Import senate commission memberships from JSON data"
  task import_commission_memberships: :environment do
    puts "Starting import of senate commission memberships..."
    Senate::CommissionMemberships.call
    puts "Import completed!"
  end
end
