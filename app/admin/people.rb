ActiveAdmin.register Person do
  permit_params :name, party_memberships_attributes: [:id, :party_id, :role, :start_date, :end_date, :_destroy]

  actions :all, except: [:destroy]

  index do
    column :id
    column :name
    column "Links" do |party|
      party.people_links.map(&:url).join(", ")
    end
    column "Parties" do |person|
      person.party_memberships.map { |pm| "#{pm.party.name} (#{pm.role})" }.join(", ")
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
      f.has_many :people_links, allow_destroy: true do |link|
        link.input :kind,
                   input_html: { class: 'chosen-select' },
                   collection: PeopleLink.kinds.keys
        link.input :url
      end
    end

    f.inputs 'Party Memberships' do
      f.has_many :party_memberships, allow_destroy: true do |pm|
        pm.input :party
        pm.input :role
        pm.input :start_date
        pm.input :end_date
      end
    end

    f.actions
  end
end