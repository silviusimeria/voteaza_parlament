module Senate
  class StructureSeeder
    PARTY_SLUGS = {
      'Partidul Social Democrat' => 'partidul-social-democrat',
      'Alianța pentru Unirea Românilor' => 'alianta-pentru-unirea-romanilor',
      'Partidul Național Liberal' => 'partidul-national-liberal', 
      'Uniunea Salvați România' => 'uniunea-salvati-romania',
      'Partidul S.O.S. România' => 'partidul-sos-romania',
      'Uniunea Democrată Maghiară din România' => 'uniunea-democrata-maghiara-din-romania',
      'Partidul Oamenilor Tineri' => 'partidul-oamenilor-tineri'
    }.freeze

    def call
      ActiveRecord::Base.transaction do
        create_mandate
        create_parliamentary_groups
        create_commissions
      end
    end
    
    private
    
    def create_mandate
      election = Election.find_by!(kind: 'parliament', election_date: '2024-12-01')
      
      @mandate = SenateMandate.find_or_create_by!(
        election: election,
        start_date: '2024-12-21',
        end_date: '2028-12-20',
        slug: '2024-2028',
        active: true
      )
    end
    
    def create_parliamentary_groups
      groups_data['groups'].each do |group_data|
        party_name = group_data['party_code']
        party_slug = PARTY_SLUGS[party_name]
        
        puts "Looking for party with slug: #{party_slug}"
        party = Party.find_by!(slug: party_slug)

        # Generate slug for parliamentary group
        group_slug = group_data['name'].downcase
          .gsub('ș', 's').gsub('ț', 't')  # Romanian special cases
          .gsub('ă', 'a').gsub('â', 'a').gsub('î', 'i')
          .gsub(/[^a-z0-9\s-]/, '')  # remove non-alphanumeric except spaces and hyphens
          .gsub(/\s+/, '-')          # replace spaces with hyphens
          .gsub(/-+/, '-')           # collapse multiple hyphens
          .gsub(/^-|-$/, '')         # trim hyphens from ends
        
        ParliamentaryGroup.find_or_create_by!(
          senate_mandate: @mandate,
          party: party,
          name: group_data['name'],
          short_name: group_data['short_name'],
          official_id: group_data['official_id'],
          slug: group_slug
        )
      end
    end
    
    def create_commissions
      commissions_data['commissions'].each do |commission_data|
        # Generate slug for commission
        commission_slug = commission_data['name'].downcase
          .gsub('ș', 's').gsub('ț', 't')  # Romanian special cases
          .gsub('ă', 'a').gsub('â', 'a').gsub('î', 'i')
          .gsub(/[^a-z0-9\s-]/, '')  # remove non-alphanumeric except spaces and hyphens
          .gsub(/\s+/, '-')          # replace spaces with hyphens
          .gsub(/-+/, '-')           # collapse multiple hyphens
          .gsub(/^-|-$/, '')         # trim hyphens from ends

        SenateCommission.find_or_create_by!(
          senate_mandate: @mandate,
          name: commission_data['name'],
          short_name: commission_data['short_name'],
          commission_type: commission_data['type'],
          official_id: commission_data['official_id'],
          slug: commission_slug
        )
      end
    end
    
    def groups_data
      @groups_data ||= load_json('parliamentary_groups.json')
    end
    
    def commissions_data
      @commissions_data ||= load_json('senate_commissions.json')
    end
    
    def load_json(filename)
      file_path = Rails.root.join('public', 'data', 'senate', filename)
      JSON.parse(File.read(file_path))
    end
  end
end