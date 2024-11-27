ActiveAdmin.register CandidateNomination do
  permit_params :county_id, :party_id, :name, :kind, :position

  index do
    selectable_column
    id_column
    column :name
    column :county
    column :party
    column :kind
    column :position
    column :links_count do |nom|
      nom.candidate_links.count
    end
    actions
  end

  filter :county
  filter :party
  filter :kind, as: :select, collection: CandidateNomination.kinds
  filter :name
end
