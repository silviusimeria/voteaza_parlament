# app/admin/counties.rb
ActiveAdmin.register County do
  permit_params :name, :code, :senate_seats, :deputy_seats

  actions :all, except: [ :create, :destroy ]

  index do
    selectable_column
    id_column
    column :name
    column :code
    column :senate_seats
    column :deputy_seats
    column :senate_candidates_count do |county|
      county.candidate_nominations.where(kind: :senate).count
    end
    column :deputy_candidates_count do |county|
      county.candidate_nominations.where(kind: :deputy).count
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :senate_seats
      f.input :deputy_seats
    end
    f.actions
  end

  filter :name
  filter :code
end
