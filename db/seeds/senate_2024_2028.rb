# Find latest general election
election = Election.find_by!(kind: 'parliament', election_date: '2024-12-01')

# Create mandate
mandate = SenateMandate.create!(
  election: election,
  start_date: '2024-12-21',  # Adjust as needed
  end_date: '2028-12-20',    # Adjust as needed
  active: true
)

# Parliamentary Group mappings
PARLIAMENTARY_GROUPS = {
  'PSD' => 'Grupul parlamentar al Partidului Social Democrat',
  'AUR' => 'Grupul parlamentar Alianța pentru Unirea Românilor',
  'PNL' => 'Grupul parlamentar al Partidului Naţional Liberal',
  'USR' => 'Grupul parlamentar al Uniunii Salvați România',
  'SOS' => 'Grupul parlamentar al Partidului S.O.S. România',
  'UDMR' => 'Grupul parlamentar al Uniunii Democrate Maghiare din România',
  'POT' => 'Grupul parlamentar al Partidului Oamenilor Tineri'
}

# Create parliamentary groups
PARLIAMENTARY_GROUPS.each do |party_code, group_name|
  party = Party.find_by!(abbreviation: party_code)
  ParliamentaryGroup.create!(
    senate_mandate: mandate,
    party: party,
    name: group_name,
    short_name: party_code
  )
end

# Create permanent commissions
PERMANENT_COMMISSIONS = [
  'Comisia juridică, de numiri, disciplină, imunităţi şi validări',
  'Comisia pentru constituţionalitate',
  'Comisia pentru buget, finanţe, activitate bancară şi piaţă de capital',
  'Comisia pentru politică externă',
  'Comisia pentru apărare, ordine publică şi siguranţă naţională',
  'Comisia pentru afaceri europene',
  'Comisia economică, industrii, servicii, turism și antreprenoriat',
  'Comisia pentru agricultură, industrie alimentară si dezvoltare rurală',
  'Comisia pentru ape, păduri, pescuit și fond cinegetic',
  'Comisia pentru administraţie publică',
  'Comisia pentru muncă, familie şi protecţie socială',
  'Comisia pentru învățământ, știință și inovare',
  'Comisia pentru sănătate',
  'Comisia pentru cultură şi media',
  'Comisia pentru transporturi şi infrastructură',
  'Comisia pentru energie, infrastructură energetică și resurse minerale',
  'Comisia pentru comunicații, tehnologia informației și inteligență artificială',
  'Comisia pentru drepturile omului, egalitate de șanse, culte şi minorităţi',
  'Comisia pentru românii de pretutindeni',
  'Comisia pentru mediu',
  'Comisia pentru cercetarea abuzurilor, combaterea corupției și petiții',
  'Comisia pentru regulament',
  'Comisia pentru tineret și sport'
]

PERMANENT_COMMISSIONS.each do |name|
  SenateCommission.create!(
    senate_mandate: mandate,
    name: name,
    commission_type: 'permanent'
  )
end

# For qualified senate nominees, assign them to their parliamentary groups
CandidateNomination.senate.qualified.each do |nomination|
  if group = ParliamentaryGroup.find_by(party: nomination.party)
    ParliamentaryGroupMembership.create!(
      parliamentary_group: group,
      candidate_nomination: nomination,
      role: 'member'  # Default role
    )
  end
end
