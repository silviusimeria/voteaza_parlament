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

  filter :party
  filter :kind, as: :select, collection: PartyLink.kinds
end
