ActiveAdmin.register CandidateNomination do
  permit_params :person_id, :county_id, :party_id, :name, :kind, :position

  actions :all, except: [:destroy]

  index do
    selectable_column
    id_column
    column :person
    column :county
    column :party
    column :kind
    column :position
    column "Links" do |party|
      party.candidate_links.map(&:url).join(", ")
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :person
      f.input :party
      f.input :county
    end

    f.inputs 'Links' do
      f.has_many :candidate_links, allow_destroy: true do |link|
        link.input :kind,
                input_html: { class: 'chosen-select' },
                collection: CandidateLink.kinds.keys
        link.input :url
      end
    end

    f.actions
  end

  filter :person
  filter :county
  filter :party
  filter :kind, as: :select, collection: CandidateNomination.kinds
  filter :name
end