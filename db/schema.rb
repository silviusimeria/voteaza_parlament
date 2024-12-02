# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_01_230501) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "candidate_nominations", force: :cascade do |t|
    t.integer "county_id", null: false
    t.integer "party_id", null: false
    t.string "name"
    t.string "kind"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "person_id"
    t.string "slug"
    t.index ["county_id", "party_id", "kind", "position"], name: "idx_nominations_unique_position", unique: true
    t.index ["county_id"], name: "index_candidate_nominations_on_county_id"
    t.index ["party_id"], name: "index_candidate_nominations_on_party_id"
    t.index ["person_id"], name: "index_candidate_nominations_on_person_id"
    t.index ["slug"], name: "index_candidate_nominations_on_slug"
  end

  create_table "counties", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "geojson_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "senate_seats", default: 0
    t.integer "deputy_seats", default: 0
    t.string "slug"
    t.index ["code"], name: "index_counties_on_code", unique: true
    t.index ["geojson_id"], name: "index_counties_on_geojson_id", unique: true
    t.index ["slug"], name: "index_counties_on_slug"
  end

  create_table "parties", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "abbreviation"
    t.text "description"
    t.string "slug"
    t.index ["name"], name: "index_parties_on_name", unique: true
    t.index ["slug"], name: "index_parties_on_slug"
  end

  create_table "party_links", force: :cascade do |t|
    t.integer "party_id", null: false
    t.string "url"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["party_id"], name: "index_party_links_on_party_id"
  end

  create_table "party_memberships", force: :cascade do |t|
    t.integer "party_id", null: false
    t.integer "person_id", null: false
    t.string "role"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["party_id"], name: "index_party_memberships_on_party_id"
    t.index ["person_id"], name: "index_party_memberships_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.json "funky_data"
    t.index ["funky_data"], name: "index_people_on_funky_data"
    t.index ["slug"], name: "index_people_on_slug"
  end

  create_table "people_links", force: :cascade do |t|
    t.integer "person_id", null: false
    t.string "kind"
    t.string "url"
    t.boolean "official", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "kind"], name: "index_people_links_on_person_id_and_kind"
    t.index ["person_id"], name: "index_people_links_on_person_id"
  end

  add_foreign_key "candidate_nominations", "counties"
  add_foreign_key "candidate_nominations", "parties"
  add_foreign_key "candidate_nominations", "people"
  add_foreign_key "party_links", "parties"
  add_foreign_key "party_memberships", "parties"
  add_foreign_key "party_memberships", "people"
  add_foreign_key "people_links", "people"
end
