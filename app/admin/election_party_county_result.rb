ActiveAdmin.register ElectionPartyCountyResult do
  menu label: "Election County Results", priority: 4, parent: "Elections"

  permit_params :election_id, :party_id, :county_id, :senate_mandates, :deputy_mandates,

  index do
    selectable_column
    id_column
    column :election
    column :county, sortable: "counties.name" do |result|
      link_to result.county.name, admin_county_path(result.county)
    end
    column :party, sortable: "parties.name" do |result|
      link_to result.party.name, admin_party_path(result.party)
    end
    column :senate_mandates
    column :deputy_mandates
    actions
  end

  controller do
    def scoped_collection
      super.includes(:county, :party)
    end
  end

  form do |f|
    f.inputs do
      f.input :election
      f.input :county
      f.input :party
      f.input :senate_mandates
      f.input :deputy_mandates
    end
    f.actions
  end

  filter :election
  filter :county
  filter :party
  filter :senate_mandates
  filter :deputy_mandates

  # Add a custom action to bulk update mandates
  batch_action :update_mandates, form: {
    senate_mandates: :number,
    deputy_mandates: :number
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |result|
      result.update(
        senate_mandates: inputs["senate_mandates"],
        deputy_mandates: inputs["deputy_mandates"]
      )
    end
    redirect_to collection_path, alert: "Mandates have been updated."
  end
end
