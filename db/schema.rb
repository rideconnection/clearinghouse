# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150714222727) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "fuzzystrmatch"
  enable_extension "postgis"
  enable_extension "hstore"
  enable_extension "postgis_topology"

  create_table "SpatialIndex", id: false, force: :cascade do |t|
    t.text   "f_table_name"
    t.text   "f_geometry_column"
    t.binary "search_frame"
  end

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         default: 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
    t.string   "request_uuid"
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "bulk_operations", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "completed",               default: false
    t.integer  "row_count"
    t.string   "file_name"
    t.datetime "last_exported_timestamp"
    t.boolean  "is_upload",               default: false
    t.integer  "error_count"
    t.string   "row_errors",                              array: true
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "eligibility_requirements", force: :cascade do |t|
    t.integer  "service_id"
    t.string   "boolean_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "eligibility_requirements", ["service_id"], name: "index_eligibility_requirements_on_service_id", using: :btree

  create_table "eligibility_rules", force: :cascade do |t|
    t.integer  "eligibility_requirement_id"
    t.string   "trip_field"
    t.string   "comparison_type"
    t.string   "comparison_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "eligibility_rules", ["eligibility_requirement_id"], name: "index_eligibility_rules_on_eligibility_requirement_id", using: :btree

  create_table "filters", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "funding_sources", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.geometry "position",     limit: {:srid=>4326, :type=>"point"}
    t.string   "phone_number"
    t.string   "common_name"
    t.string   "jurisdiction"
    t.string   "address_type"
  end

  create_table "nonces", force: :cascade do |t|
    t.string   "nonce"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nonces", ["created_at"], name: "index_nonces_on_created_at", using: :btree
  add_index "nonces", ["nonce", "provider_id"], name: "index_nonces_on_nonce_and_provider_id", unique: true, using: :btree
  add_index "nonces", ["provider_id"], name: "index_nonces_on_provider_id", using: :btree

  create_table "old_passwords", force: :cascade do |t|
    t.string   "encrypted_password",       null: false
    t.string   "password_salt"
    t.string   "password_archivable_type", null: false
    t.integer  "password_archivable_id",   null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable", using: :btree

  create_table "open_capacities", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "seats_open"
    t.integer  "wheelchair_spaces_open"
    t.integer  "scooter_spaces_open"
    t.text     "notes"
    t.datetime "departure_time"
    t.integer  "departure_location_id"
    t.datetime "arrival_time"
    t.integer  "arrival_location_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "open_capacities", ["service_id"], name: "index_open_capacities_on_service_id", using: :btree

  create_table "operating_hours", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "day_of_week"
    t.time     "open_time"
    t.time     "close_time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "operating_hours", ["service_id"], name: "index_operating_hours_on_service_id", using: :btree

  create_table "provider_relationships", force: :cascade do |t|
    t.integer  "requesting_provider_id"
    t.integer  "cooperating_provider_id"
    t.date     "approved_at"
    t.boolean  "automatic_requester_approval"
    t.boolean  "automatic_cooperator_approval"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "provider_relationships", ["cooperating_provider_id"], name: "index_provider_relationships_on_cooperating_provider_id", using: :btree
  add_index "provider_relationships", ["requesting_provider_id"], name: "index_provider_relationships_on_requesting_provider_id", using: :btree

  create_table "providers", force: :cascade do |t|
    t.string   "name"
    t.integer  "address_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "api_key"
    t.string   "private_key"
    t.string   "primary_contact_email"
    t.integer  "trip_ticket_expiration_days_before"
    t.time     "trip_ticket_expiration_time_of_day"
  end

  add_index "providers", ["api_key"], name: "index_providers_on_api_key", unique: true, using: :btree

  create_table "roles", force: :cascade do |t|
    t.string "name"
  end

  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "service_requests", force: :cascade do |t|
    t.integer  "trip_ticket_id"
    t.integer  "open_capacity_id"
    t.integer  "status"
    t.integer  "user_id"
    t.text     "notes"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "service_requests", ["trip_ticket_id"], name: "index_service_requests_on_trip_ticket_id", using: :btree

  create_table "services", force: :cascade do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.integer  "funding_source_id"
    t.text     "rate"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.integer  "operating_hours_id"
    t.geometry "service_area",       limit: {:srid=>4326, :type=>"polygon"}
    t.hstore   "eligibility"
    t.string   "service_area_type"
  end

  add_index "services", ["provider_id"], name: "index_services_on_provider_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "spatialite_history", primary_key: "event_id", force: :cascade do |t|
    t.text "table_name",      null: false
    t.text "geometry_column"
    t.text "event",           null: false
    t.text "timestamp",       null: false
    t.text "ver_sqlite",      null: false
    t.text "ver_splite",      null: false
  end

  create_table "trip_claims", force: :cascade do |t|
    t.integer  "claimant_provider_id"
    t.integer  "claimant_service_id"
    t.integer  "trip_ticket_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.datetime "proposed_pickup_time"
    t.string   "proposed_fare"
    t.text     "notes"
    t.integer  "claimant_customer_id"
    t.integer  "claimant_trip_id"
    t.string   "status"
  end

  add_index "trip_claims", ["claimant_provider_id"], name: "index_trip_claims_on_claimant_provider_id", using: :btree
  add_index "trip_claims", ["status"], name: "index_trip_claims_on_status", using: :btree
  add_index "trip_claims", ["trip_ticket_id"], name: "index_trip_claims_on_trip_ticket_id", using: :btree

  create_table "trip_results", force: :cascade do |t|
    t.integer  "trip_ticket_id"
    t.integer  "trip_claim_id"
    t.string   "outcome"
    t.time     "actual_pick_up_time"
    t.time     "actual_drop_off_time"
    t.integer  "rate_type"
    t.decimal  "rate",                   precision: 10, scale: 2
    t.string   "driver_id"
    t.integer  "vehicle_type"
    t.integer  "vehicle_id"
    t.integer  "fare_type"
    t.decimal  "base_fare",              precision: 10, scale: 2
    t.decimal  "fare",                   precision: 10, scale: 2
    t.float    "miles_traveled"
    t.float    "odometer_start"
    t.float    "odometer_end"
    t.float    "billable_mileage"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "extra_securement_count"
    t.text     "notes"
  end

  add_index "trip_results", ["trip_ticket_id"], name: "index_trip_results_on_trip_ticket_id", using: :btree

  create_table "trip_ticket_comments", force: :cascade do |t|
    t.integer  "trip_ticket_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trip_ticket_comments", ["trip_ticket_id"], name: "index_trip_ticket_comments_on_trip_ticket_id", using: :btree

  create_table "trip_tickets", force: :cascade do |t|
    t.integer  "origin_provider_id"
    t.string   "origin_customer_id"
    t.boolean  "customer_information_withheld"
    t.date     "customer_dob"
    t.integer  "customer_address_id"
    t.string   "customer_primary_phone"
    t.string   "customer_emergency_phone"
    t.text     "customer_impairment_description"
    t.integer  "customer_boarding_time"
    t.integer  "customer_deboarding_time"
    t.integer  "customer_seats_required"
    t.text     "customer_notes"
    t.string   "origin_trip_id"
    t.integer  "pick_up_location_id"
    t.integer  "drop_off_location_id"
    t.string   "scheduling_priority"
    t.integer  "num_attendants"
    t.integer  "num_guests"
    t.string   "trip_purpose_description"
    t.text     "trip_notes"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.string   "customer_primary_language"
    t.string   "customer_first_name"
    t.string   "customer_last_name"
    t.string   "customer_middle_name"
    t.time     "requested_pickup_time"
    t.time     "requested_drop_off_time"
    t.hstore   "customer_identifiers"
    t.string   "customer_ethnicity"
    t.string   "customer_eligibility_factors",                                           array: true
    t.string   "customer_mobility_factors",                                              array: true
    t.string   "customer_service_animals",                                               array: true
    t.string   "trip_funders",                                                           array: true
    t.string   "customer_race"
    t.time     "earliest_pick_up_time"
    t.datetime "appointment_time"
    t.integer  "provider_white_list",                                                    array: true
    t.integer  "provider_black_list",                                                    array: true
    t.boolean  "rescinded",                                 default: false, null: false
    t.datetime "expire_at"
    t.boolean  "expired",                                   default: false
    t.string   "customer_service_level"
    t.string   "customer_gender",                 limit: 1
    t.integer  "estimated_distance"
    t.integer  "time_window_before"
    t.integer  "time_window_after"
    t.hstore   "additional_data"
  end

  add_index "trip_tickets", ["customer_eligibility_factors"], name: "customer_eligibility_factors", using: :gin
  add_index "trip_tickets", ["customer_identifiers"], name: "customer_identifiers", using: :gin
  add_index "trip_tickets", ["customer_mobility_factors"], name: "customer_mobility_factors", using: :gin
  add_index "trip_tickets", ["customer_service_animals"], name: "customer_service_animals", using: :gin
  add_index "trip_tickets", ["customer_service_level"], name: "customer_service_level", using: :btree
  add_index "trip_tickets", ["expired"], name: "index_trip_tickets_on_expired", using: :btree
  add_index "trip_tickets", ["origin_provider_id"], name: "index_trip_tickets_on_origin_provider_id", using: :btree
  add_index "trip_tickets", ["provider_black_list"], name: "provider_black_list", using: :gin
  add_index "trip_tickets", ["provider_white_list"], name: "provider_white_list", using: :gin
  add_index "trip_tickets", ["trip_funders"], name: "trip_funders", using: :gin

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "name"
    t.string   "title"
    t.string   "phone"
    t.integer  "provider_id"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "encrypted_password",                  default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",                       default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "active",                              default: true, null: false
    t.integer  "role_id"
    t.string   "notification_preferences",                                        array: true
    t.datetime "password_changed_at"
    t.integer  "failed_attempts",                     default: 0
    t.datetime "locked_at"
    t.string   "unique_session_id",        limit: 20
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["notification_preferences"], name: "notification_preferences_index", using: :gin
  add_index "users", ["password_changed_at"], name: "index_users_on_password_changed_at", using: :btree
  add_index "users", ["provider_id"], name: "index_users_on_provider_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "waypoints", force: :cascade do |t|
    t.integer  "open_capacity_id"
    t.integer  "sequence_id"
    t.datetime "arrival_time"
    t.integer  "location_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

end
