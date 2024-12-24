ActiveAdmin.register ParliamentaryGroupMembership do
  menu label: "Parliament Groups", parent: "Parliament"

  permit_params :parliamentary_group_id, :candidate_nomination_id, :role, :official_id


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
      row :person do |membership|
        candidate = membership.candidate_nomination.person
        link_to candidate.name, admin_person_path(candidate)
      end
      row :role
    end
  end

  form do |f|
    f.inputs do
      f.input :parliamentary_group, collection: ParliamentaryGroup.all.map { |pg| [ pg.name, pg.id ] }
      f.input :candidate_nomination, collection: CandidateNomination
        .includes(:person, :county, :party)
        .map { |cn| [ "#{cn.name} (#{cn.party&.name}) (#{cn.county&.name})", cn.id ] }
      f.input :role, as: :select, collection: ParliamentaryGroupMembership::ROLES
    end
    f.actions
  end

  filter :parliamentary_group
  filter :role, as: :select, collection: ParliamentaryGroupMembership::ROLES

  controller do
    def scoped_collection
      super.includes(:parliamentary_group, :candidate_nomination)
    end
  end
end
