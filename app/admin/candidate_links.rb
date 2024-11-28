ActiveAdmin.register CandidateLink do
  permit_params :candidate_nomination_id, :url, :kind

  index do
    selectable_column
    id_column
    column :candidate_nomination
    column :kind
    column :url do |link|
      link_to link.url, link.url, target: "_blank" if link.url.present?
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :candidate_nomination,
              input_html: { class: 'chosen-select' },
              collection: CandidateNomination.includes(:county, :party).order('name ASC').map { |cn|
                ["#{cn.name} (#{cn.county&.name} - #{cn.party&.name})", cn.id]
              }
      f.input :kind,
              input_html: { class: 'chosen-select' },
              collection: CandidateLink.kinds.keys
      f.input :url
    end
    f.actions
  end

  filter :candidate_nomination
  filter :kind, as: :select, collection: CandidateLink.kinds
end
