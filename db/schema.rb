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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130221031929) do

  create_table "SpatialIndex", :id => false, :force => true do |t|
    t.text   "f_table_name"
    t.text   "f_geometry_column"
    t.binary "search_frame"
  end

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "funding_sources", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.spatial  "position",   :limit => {:srid=>4326, :type=>"point"}
  end

  create_table "nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "provider_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "nonces", ["created_at"], :name => "index_nonces_on_created_at"
  add_index "nonces", ["nonce", "provider_id"], :name => "index_nonces_on_nonce_and_provider_id", :unique => true
  add_index "nonces", ["provider_id"], :name => "index_nonces_on_provider_id"

  create_table "open_capacities", :force => true do |t|
    t.integer  "service_id"
    t.integer  "seats_open"
    t.integer  "wheelchair_spaces_open"
    t.integer  "scooter_spaces_open"
    t.text     "notes"
    t.datetime "departure_time"
    t.integer  "departure_location_id"
    t.datetime "arrival_time"
    t.integer  "arrival_location_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "open_capacities", ["service_id"], :name => "index_open_capacities_on_service_id"

  create_table "operating_hours", :force => true do |t|
    t.integer  "service_id"
    t.integer  "day_of_week"
    t.time     "open_time"
    t.time     "close_time"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "operating_hours", ["service_id"], :name => "index_operating_hours_on_service_id"

  create_table "provider_relationships", :force => true do |t|
    t.integer  "requesting_provider_id"
    t.integer  "cooperating_provider_id"
    t.date     "approved_at"
    t.boolean  "automatic_requester_approval"
    t.boolean  "automatic_cooperator_approval"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "provider_relationships", ["cooperating_provider_id"], :name => "index_provider_relationships_on_cooperating_provider_id"
  add_index "provider_relationships", ["requesting_provider_id"], :name => "index_provider_relationships_on_requesting_provider_id"

  create_table "providers", :force => true do |t|
    t.string   "name"
    t.integer  "address_id"
    t.integer  "primary_contact_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "api_key"
    t.string   "private_key"
    t.boolean  "active"
  end

  add_index "providers", ["api_key"], :name => "index_providers_on_api_key", :unique => true

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true
  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "service_requests", :force => true do |t|
    t.integer  "trip_ticket_id"
    t.integer  "open_capacity_id"
    t.integer  "status"
    t.integer  "user_id"
    t.text     "notes"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "service_requests", ["trip_ticket_id"], :name => "index_service_requests_on_trip_ticket_id"

  create_table "services", :force => true do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.integer  "funding_source_id"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "operating_hours_id"
    t.text     "rate"
    t.hstore   "eligibility"
    t.spatial  "service_area",       :limit => {:srid=>4326, :type=>"polygon"}
  end

  add_index "services", ["provider_id"], :name => "index_services_on_provider_id"

  create_table "spatialite_history", :primary_key => "event_id", :force => true do |t|
    t.text "table_name",      :null => false
    t.text "geometry_column"
    t.text "event",           :null => false
    t.text "timestamp",       :null => false
    t.text "ver_sqlite",      :null => false
    t.text "ver_splite",      :null => false
  end

  create_table "trip_claims", :force => true do |t|
    t.integer  "origin_provider_id"
    t.integer  "claimant_provider_id"
    t.integer  "trip_ticket_id"
    t.integer  "status"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "claimant_service_id"
    t.datetime "proposed_pickup_time"
    t.string   "proposed_fare"
    t.text     "notes"
    t.integer  "claimant_customer_id"
    t.integer  "claimant_trip_id"
  end

  add_index "trip_claims", ["claimant_provider_id"], :name => "index_trip_claims_on_claimant_provider_id"
  add_index "trip_claims", ["trip_ticket_id"], :name => "index_trip_claims_on_trip_ticket_id"

  create_table "trip_results", :force => true do |t|
    t.integer  "trip_ticket_id"
    t.integer  "trip_claim_id"
    t.integer  "outcome"
    t.time     "actual_pick_up_time"
    t.time     "actual_drop_off_time"
    t.integer  "rate_type"
    t.integer  "rate"
    t.integer  "driver_id"
    t.integer  "vehicle_type"
    t.integer  "vehicle_id"
    t.integer  "fare_type"
    t.integer  "base_fare"
    t.integer  "fare"
    t.float    "miles_travelled"
    t.float    "odometer_start"
    t.float    "odometer_end"
    t.float    "billable_mileage"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.integer  "extra_securement_count"
  end

  add_index "trip_results", ["trip_ticket_id"], :name => "index_trip_results_on_trip_ticket_id"

  create_table "trip_ticket_comments", :force => true do |t|
    t.integer  "trip_ticket_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "trip_ticket_comments", ["trip_ticket_id"], :name => "index_trip_ticket_comments_on_trip_ticket_id"

  create_table "trip_tickets", :force => true do |t|
    t.integer      "origin_provider_id"
    t.string       "origin_customer_id"
    t.integer      "claimant_provider_id"
    t.boolean      "customer_information_withheld"
    t.date         "customer_dob"
    t.integer      "customer_address_id"
    t.string       "customer_primary_phone"
    t.string       "customer_emergency_phone"
    t.text         "customer_impairment_description"
    t.integer      "customer_boarding_time"
    t.integer      "customer_deboarding_time"
    t.integer      "customer_seats_required"
    t.text         "customer_notes"
    t.integer      "origin_trip_id"
    t.integer      "claimant_trip_id"
    t.integer      "pick_up_location_id"
    t.integer      "drop_off_location_id"
    t.string       "scheduling_priority"
    t.integer      "allowed_time_variance"
    t.integer      "num_attendants"
    t.integer      "num_guests"
    t.string       "trip_purpose_code"
    t.string       "trip_purpose_description"
    t.text         "trip_notes"
    t.datetime     "created_at",                                          :null => false
    t.datetime     "updated_at",                                          :null => false
    t.string       "customer_primary_language"
    t.string       "customer_first_name"
    t.string       "customer_last_name"
    t.string       "customer_middle_name"
    t.time         "requested_pickup_time"
    t.time         "requested_drop_off_time"
    t.hstore       "customer_identifiers"
    t.string_array "customer_mobility_impairments",        :limit => 255
    t.string       "customer_ethnicity"
    t.string_array "customer_eligibility_factors",         :limit => 255
    t.string_array "customer_assistive_devices",           :limit => 255
    t.string_array "customer_service_animals",             :limit => 255
    t.string_array "guest_or_attendant_service_animals",   :limit => 255
    t.string_array "guest_or_attendant_assistive_devices", :limit => 255
    t.string_array "trip_funders",                         :limit => 255
    t.string       "customer_race"
    t.time         "earliest_pick_up_time"
    t.datetime     "appointment_time"
  end

  add_index "trip_tickets", ["customer_assistive_devices"], :name => "customer_assistive_devices"
  add_index "trip_tickets", ["customer_eligibility_factors"], :name => "customer_eligibility_factors"
  add_index "trip_tickets", ["customer_identifiers"], :name => "customer_identifiers"
  add_index "trip_tickets", ["customer_mobility_impairments"], :name => "customer_mobility_impairments"
  add_index "trip_tickets", ["customer_service_animals"], :name => "customer_service_animals"
  add_index "trip_tickets", ["guest_or_attendant_assistive_devices"], :name => "guest_or_attendant_assistive_devices"
  add_index "trip_tickets", ["guest_or_attendant_service_animals"], :name => "guest_or_attendant_service_animals"
  add_index "trip_tickets", ["origin_provider_id"], :name => "index_trip_tickets_on_origin_provider_id"
  add_index "trip_tickets", ["trip_funders"], :name => "trip_funders"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "title"
    t.string   "phone"
    t.integer  "provider_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "encrypted_password",     :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "active",                 :default => true, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["provider_id"], :name => "index_users_on_provider_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "waypoints", :force => true do |t|
    t.integer  "open_capacity_id"
    t.integer  "sequence_id"
    t.datetime "arrival_time"
    t.integer  "location_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

end
