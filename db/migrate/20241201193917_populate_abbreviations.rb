class PopulateAbbreviations < ActiveRecord::Migration[8.0]
  def up
    # First, add the column if it doesn't exist
    unless column_exists?(:parties, :abbreviation)
      add_column :parties, :abbreviation, :string
    end

    # Define abbreviations
    abbreviations = {
      "alianta-pentru-unirea-romanilor" => "AUR",
      "alternativa-pentru-demnitate-nationala" => "ADN",
      "dreptate-si-respect-in-europa-pentru-toti" => "DREPT",
      "forta-dreptei" => "FD",
      "partidul-ecologist-roman" => "PER",
      "partidul-national-conservator-roman" => "PNCR",
      "partidul-national-liberal" => "PNL",
      "partidul-noua-romanie" => "PNR",
      "partidul-oamenilor-tineri" => "POT",
      "partidul-phralipe-al-romilor" => "PPR",
      "reinnoim-proiectul-european-al-romaniei" => "REPER",
      "partidul-republican-din-romania" => "PRR",
      "partidul-romania-in-actiune" => "PRIA",
      "partidul-social-democrat" => "PSD",
      "partidul-social-democrat-independent" => "PSDI",
      "partidul-social-democrat-unit" => "PSDU",
      "partidul-sos-romania" => "SOS",
      "patriotii-poporului-roman" => "PPR",
      "uniunea-democrata-maghiara-din-romania" => "UDMR",
      "uniunea-salvati-romania" => "USR",
      "alianta-national-crestina" => "ANC",
      "partidul-liga-actiunii-nationale" => "PLAN",
      "romania-socialista" => "RS",
      "sanatate-educaie-natura-sustenabilitate" => "SENS",
      "partidul-dreptatii" => "PD",
      "partidul-uniunea-geto-dacilor" => "PGD",
      "partidul-patria" => "PP",
      "candidat-independent" => "IND",
      "partidul-verde" => "PV",
      "partidul-oamenilor-credinciosi" => "POC",
      "partidul-national-taranesc-crestin-democrat" => "PNTCD",
      "partidul-pensionarilor-uniti" => "PPU",
      "asociatia-italienilor-din-romania-roasit" => "RO-IT",
      "asociatia-liga-albanezilor-din-romania" => "ALAR",
      "asociatia-macedonenilor-din-romania" => "AMR",
      "asociatia-partida-romilor-pro-europa" => "APRPE",
      "comunitatea-rusilor-lipoveni-din-romania" => "CRLR",
      "federatia-comunitatilor-evreiesti-din-romania" => "FCER",
      "forumul-cehilor-din-romania" => "FCR",
      "forumul-democrat-al-germanilor-din-romania" => "FDGR",
      "uniunea-armenilor-din-romania" => "UAR",
      "uniunea-bulgara-din-banat-romania" => "UBB",
      "uniunea-croatilor-din-romania" => "UCR",
      "uniunea-culturala-a-rutenilor-din-romania" => "UCRR",
      "uniunea-democrata-a-tatarilor-turco-musulmani-din-romania" => "UDTTMR",
      "uniunea-democrata-turca-din-romania" => "UDTR",
      "uniunea-democratica-a-slovacilor-si-cehilor-din-romania" => "UDSCR",
      "uniunea-elena-din-romania" => "UER",
      "uniunea-polonezilor-din-romania" => "UPR",
      "uniunea-sarbilor-din-romania" => "USR-SB",
      "uniunea-ucrainenilor-din-romania" => "UUR"
    }

    # Update each party
    abbreviations.each do |slug, abbr|
      execute <<-SQL
        UPDATE parties 
        SET abbreviation = '#{abbr}'
        WHERE slug = '#{slug}';
      SQL
    end
  end

  def down
    # If you need to rollback, just nullify the abbreviations
    execute "UPDATE parties SET abbreviation = NULL;"
  end
end
