# app/admin/senate_commission_membership.rb
ActiveAdmin.register SenateCommissionMembership do
  menu label: "Senate Commissions", parent: "Parliament"

  # Permit params
  permit_params :senate_commission_id, :candidate_nomination_id, :role, :official_id

  # Index view
  index do
    selectable_column
    id_column
    column :senate_commission do |m|
      m.senate_commission.name
    end
    column :senator do |m|
      link_to m.candidate_nomination.person.name, admin_person_path(m.candidate_nomination.person)
    end
    column :role
    column "Mandate" do |m|
      m.senate_commission.senate_mandate.slug
    end
    actions
  end

  # Filter options
  filter :senate_commission, collection: proc {
    SenateCommission.includes(:senate_mandate)
                    .order("senate_mandates.start_date DESC, name")
                    .map { |c| [ c.name, c.id ] }
  }
  filter :role, as: :select, collection: SenateCommissionMembership::ROLES
  filter :candidate_nomination_person_name, as: :string, label: "Senator Name"
  filter :mandate, collection: proc {
    SenateMandate.order(start_date: :desc).map { |mandate| [ mandate.slug, mandate.id ]
    }}, label: "Mandate"


  # Show page
  show do
    attributes_table do
      row :id
      row :senate_commission do |m|
        m.senate_commission.name
      end
      row :senator do |m|
        link_to m.candidate_nomination.person.name, admin_person_path(m.candidate_nomination.person)
      end
      row :role
    end
    active_admin_comments
  end

  # Form
  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :senate_commission, collection: SenateCommission.includes(:senate_mandate)
                                                              .order("senate_mandates.start_date DESC, name")
                                                              .map { |c| [ c.name, c.id ] }

      f.input :candidate_nomination, collection: CandidateNomination.includes(:person, :party, :election)
                                                                    .where(kind: "senate")
                                                                    .order("people.name")
                                                                    .map { |n| [ "#{n.person.name} (#{n.party.name}) (#{n.election.name})", n.id ] }

      f.input :role, as: :select, collection: SenateCommissionMembership::ROLES
    end
    f.actions
  end
end
