ActiveAdmin.register PartyLink do
  permit_params :party_id, :url, :kind

  index do
    selectable_column
    id_column
    column :party
    column :kind
    column :url do |link|
      link_to link.url, link.url, target: "_blank" if link.url.present?
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :party,
              input_html: { class: 'chosen-select' },
              collection: Party.order('name ASC').map { |p|
                [p.name, p.id]
              }
      f.input :kind
      f.input :url
    end
    f.actions
  end

  filter :party
  filter :kind, as: :select, collection: PartyLink.kinds
end
