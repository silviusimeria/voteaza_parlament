ActiveAdmin.register Person do
  permit_params :name, party_memberships_attributes: [:id, :party_id, :role, :start_date, :end_date, :_destroy]

  actions :all, except: [:destroy]

  index do
    column :id
    column :name
    column "Parties" do |person|
      person.party_memberships.map { |pm| "#{pm.party.name} (#{pm.role})" }.join(", ")
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
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