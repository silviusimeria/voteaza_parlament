ActiveAdmin.register Party do
  permit_params :name, :color, :logo_url, :website

  index do
    selectable_column
    id_column
    column :name
    column :color do |party|
      span class: "color-box", style: "background-color: #{party.color};" if party.color.present?
      span party.color
    end
    column :website
    column :candidates_count do |party|
      party.candidate_nominations.count
    end
    actions
  end

  filter :name
end
