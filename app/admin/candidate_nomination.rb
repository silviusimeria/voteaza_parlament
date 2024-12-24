ActiveAdmin.register CandidateNomination do
  menu label: "Candidate Nominations", parent: "Elections"

  permit_params :name, :kind, :position, :county_id, :party_id, :person_id, :qualified, :election_id

  index do
    selectable_column
    id_column
    column :name, sortable: "people.name" do |result|
      link_to result.person.name, admin_person_path(result.person)
    end
    column :county, sortable: "counties.name" do |result|
      link_to result.county.name, admin_county_path(result.county)
    end

    column :party, sortable: "parties.name" do |result|
      link_to result.party.name, admin_party_path(result.party)
    end
    column :kind
    column :position
    column :qualified
    column :mandate_started

    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :county
      f.input :party
      f.input :person
      f.input :kind, as: :select, collection: CandidateNomination.kinds.keys
      f.input :position
      f.input :qualified
      f.input :mandate_started
      f.input :election
    end
    f.actions
  end

  filter :name
  filter :county
  filter :party
  filter :kind, as: :select, collection: CandidateNomination.kinds.keys
  filter :qualified
  filter :mandate_started
  filter :election

  controller do
    def scoped_collection
      super.includes(:county, :party)
    end
  end

  batch_action :mark_as_qualified do |ids|
    batch_action_collection.find(ids).each do |nomination|
      nomination.update(qualified: true)
    end
    redirect_to collection_path, alert: "Selected candidates have been marked as qualified."
  end

  batch_action :mark_as_unqualified do |ids|
    batch_action_collection.find(ids).each do |nomination|
      nomination.update(qualified: false)
    end
    redirect_to collection_path, alert: "Selected candidates have been marked as unqualified."
  end
end
