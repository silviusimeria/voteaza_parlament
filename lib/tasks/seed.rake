namespace :seed do
  desc "Initializeaza datele pentru alegerile parlamentare 2024"
  task elections_2024: :environment do
    ActiveRecord::Base.transaction do
      # Creeaza alegerile
      election = Election.create!(
        name: "Parliamentary Elections 2024",
        kind: "parliament",
        election_date: Date.new(2024, 12, 1),
        active: true
      )

      # Dezactiveaza alte alegeri parlamentare
      Election.parliament.where.not(id: election.id).update_all(active: false)

      # Seteaza datele pentru judete
      County.find_each do |county|
        ElectionCountyDatum.create!(
          election: election,
          county: county,
          senate_seats: county.read_attribute_before_type_cast(:senate_seats),
          deputy_seats: county.read_attribute_before_type_cast(:deputy_seats)
        )
      end

      # Actualizeaza nominalizarile existente
      CandidateNomination.update_all(election_id: election.id)
    end
    puts "Alegerile parlamentare 2024 au fost initializate cu succes"
  rescue => e
    puts "Eroare: #{e.message}"
  end
end
