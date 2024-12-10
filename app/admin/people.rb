ActiveAdmin.register Person do
  permit_params :name, :funky_data,
                people_links_attributes: [:id, :kind, :url, :official, :_destroy],
                party_memberships_attributes: [:id, :party_id, :role, :start_date, :end_date, :_destroy]

  actions :all, except: [:destroy]

  index do
    selectable_column
    id_column
    column :name
    column :birth_date
    column :education_level
    column :previous_role
    column "Links Count" do |person|
      person.people_links.count
    end
    column "Memberships" do |person|
      person.party_memberships.map { |pm| "#{pm.party.name} (#{pm.role})" }.join(", ")
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :birth_date
      row :education_level
      row :previous_role
      row :integrity_issues
      row :created_at
      row :updated_at
    end

    panel "Links" do
      table_for resource.people_links do
        column :kind
        column :url do |link|
          link_to link.url, link.url, target: '_blank'
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
      f.input :funky_data
    end

    # This broken for some reason
    # f.inputs 'Links' do
    #   f.has_many :people_links, allow_destroy: true do |link|
    #     link.input :kind,
    #                input_html: { class: 'chosen-select' },
    #                collection: PeopleLink.kinds.keys
    #     link.input :url
    #   end
    # end
    f.actions
  end

  filter :name
  filter :created_at
  filter :updated_at
  filter :parties
  filter :counties

  controller do
    def scoped_collection
      super.includes(:people_links, :party_memberships, party_memberships: [:party])
    end
  end
end