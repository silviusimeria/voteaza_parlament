# app/admin/counties.rb
ActiveAdmin.register County do
  permit_params :name, :code

  index do
    selectable_column
    id_column
    column :name
    column :code
    column :candidates_count do |county|
      county.candidate_nominations.count
    end
    actions
  end

  filter :name
  filter :code
end
