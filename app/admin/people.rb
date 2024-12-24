ActiveAdmin.register Person do
  permit_params :name, :funky_data,
                people_links_attributes: [ :id, :kind, :url, :official, :_destroy ],
                party_memberships_attributes: [ :id, :party_id, :role, :start_date, :end_date, :_destroy ]

  actions :all, except: [ :destroy ]

  index do
    selectable_column
    id_column
    column :name
    column :dob
    column :parliament_id
    actions
  end

  show do
    attributes_table do
      row :name
      row :dob
      row :parliament_id
      row :funky_data
    end

    panel "Candidate Nominations" do
      table_for resource.candidate_nominations do
        column :id do |nomination|
          link_to nomination.id, admin_candidate_nomination_path(nomination)
        end
        column :kind
        column :election
        column :county
        column :party
        column :position
        column :mandate_allocated
        column :mandate_started
        end
    end

    panel "Links" do
      table_for resource.people_links do
        column :kind
        column :url do |link|
          link_to link.url, link.url, target: "_blank"
        end
        column :official
      end
    end

    panel "Party Memberships" do
      table_for resource.party_memberships do
        column :party
        column :role
        column :start_date
        column :end_date
      end
    end
  end

  form do |f|
    f.inputs "Basic Information" do
      f.input :name
      f.input :dob
      f.input :parliament_id
      f.input :funky_data
    end
    f.actions
  end

  filter :name

  controller do
    def scoped_collection
      super.includes(:people_links, :party_memberships, party_memberships: [ :party ])
    end
  end
end
