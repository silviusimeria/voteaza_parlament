ActiveAdmin.register Party do
  permit_params :name, :color, :logo_url, :website, :abbreviation, :description,
                party_links_attributes: [:id, :url, :kind, :_destroy]

  actions :all, except: [:create, :destroy]

  index do
    selectable_column
    id_column
    column :name
    column :abbreviation
    column :description
    column :president do |party|
      party.members.first&.name
    end
    column :color do |party|
      span class: "color-box", style: "background-color: #{party.color};" if party.color.present?
      span party.color
    end
    column :candidates_count do |party|
      party.candidate_nominations.count
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :abbreviation
      f.input :color
      f.input :logo_url
      f.inputs 'Links' do
        f.has_many :party_links, allow_destroy: true do |link|
          link.input :kind,
                  input_html: { class: 'chosen-select' },
                  collection: PartyLink.kinds.keys
          link.input :url
        end
      end
    end
    f.actions
  end

  filter :name
  filter :abbreviation
end
