ActiveAdmin.register ParliamentaryGroupMembership do

  permit_params :parliamentary_group_id, :candidate_nomination_id, :role, :official_id

  filter :parliamentary_group
  filter :candidate_nomination_id
  filter :role

  index do
    selectable_column
    id_column
    column :parliamentary_group
    column :candidate_nomination do |membership|
      candidate = membership.candidate_nomination
      link_to candidate.name, admin_candidate_nomination_path(candidate)
    end
    column :role
    actions
  end

  show do
    attributes_table do
      row :id
      row :parliamentary_group
      row :candidate_nomination do |membership|
        candidate = membership.candidate_nomination
        link_to candidate.name, admin_candidate_nomination_path(candidate)
      end
      row :role
    end
  end

  form do |f|
    f.inputs do
      f.input :parliamentary_group, collection: ParliamentaryGroup.all.map { |pg| [pg.name, pg.id] }
      f.input :candidate_nomination, collection: CandidateNomination
        .includes(:person)
        .map { |cn| ["#{cn.name} (#{cn.county&.name})", cn.id] }
      f.input :role
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:parliamentary_group, :candidate_nomination)
    end
  end
end