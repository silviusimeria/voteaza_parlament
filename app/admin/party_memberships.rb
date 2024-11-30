ActiveAdmin.register PartyMembership do
  permit_params :party_id, :person_id, :role, :start_date, :end_date

  actions :all, except: [:destroy]

  index do
    column :id
    column :person
    column :party
    column :role
    column :start_date
    column :end_date
    actions
  end

  form do |f|
    f.inputs do
      f.input :person
      f.input :party
      f.input :role
      f.input :start_date
      f.input :end_date
    end
    f.actions
  end
end