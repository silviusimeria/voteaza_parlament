# app/admin/election_party_result.rb
ActiveAdmin.register ElectionPartyResult do
  menu label: "Election Party Results", parent: "Elections"

  permit_params :election_id, :county_id, :party_id, :votes_cd,
                :percentage_cd, :votes_senate, :percentage_senate,
                :deputy_mandates, :senate_mandates

  index do
    selectable_column
    column :election
    column :county
    column :party
    column :votes_cd
    column :percentage_cd
    column :votes_senate
    column :percentage_senate
    column :deputy_mandates
    column :senate_mandates
    actions
  end

  filter :election
  filter :county
  filter :party
  filter :percentage_cd
  filter :percentage_senate

  form do |f|
    f.inputs do
      f.input :election
      f.input :county
      f.input :party
      f.input :votes_cd
      f.input :percentage_cd
      f.input :votes_senate
      f.input :percentage_senate
      f.input :deputy_mandates
      f.input :senate_mandates
    end
    f.actions
  end

  csv do
    column :election
    column(:county) { |r| r.county.name }
    column(:party) { |r| r.party.name }
    column :votes_cd
    column :percentage_cd
    column :votes_senate
    column :percentage_senate
    column :deputy_mandates
    column :senate_mandates
  end

  # Show page
  show do
    attributes_table do
      row :election
      row :county
      row :party
      row :votes_cd
      row :percentage_cd
      row :votes_senate
      row :percentage_senate
      row :deputy_mandates
      row :senate_mandates
      row :created_at
      row :updated_at
    end
  end
end
