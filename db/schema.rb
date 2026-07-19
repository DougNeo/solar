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

ActiveRecord::Schema[8.1].define(version: 2026_07_18_000000) do
  create_table "alerts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "device_id"
    t.string "external_id", null: false
    t.text "influence"
    t.json "metadata", default: {}
    t.datetime "occurred_at"
    t.integer "plant_id", null: false
    t.datetime "resolved_at"
    t.string "severity"
    t.text "solution"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_alerts_on_device_id"
    t.index ["external_id"], name: "index_alerts_on_external_id", unique: true
    t.index ["plant_id"], name: "index_alerts_on_plant_id"
  end

  create_table "devices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_type"
    t.datetime "last_collected_at"
    t.string "name"
    t.integer "plant_id", null: false
    t.string "serial", null: false
    t.string "status"
    t.json "telemetry", default: {}
    t.datetime "updated_at", null: false
    t.index ["plant_id"], name: "index_devices_on_plant_id"
    t.index ["serial"], name: "index_devices_on_serial", unique: true
  end

  create_table "energy_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "generation_kwh", precision: 14, scale: 3
    t.json "metrics", default: {}
    t.integer "plant_id", null: false
    t.decimal "power_kw", precision: 12, scale: 3
    t.date "recorded_on", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_id", "recorded_on"], name: "index_energy_readings_on_plant_id_and_recorded_on", unique: true
    t.index ["plant_id"], name: "index_energy_readings_on_plant_id"
  end

  create_table "injected_energies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.decimal "energy"
    t.datetime "updated_at", null: false
  end

  create_table "plants", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.decimal "current_power_kw", precision: 12, scale: 3
    t.decimal "daily_energy_kwh", precision: 14, scale: 3
    t.float "installed_capacity"
    t.datetime "last_synced_at"
    t.decimal "latitude"
    t.decimal "longitude"
    t.json "metadata", default: {}
    t.string "name"
    t.string "plant_id"
    t.datetime "start_operating_time"
    t.string "status"
    t.decimal "total_energy_kwh", precision: 16, scale: 3
    t.datetime "updated_at", null: false
    t.index ["plant_id"], name: "index_plants_on_plant_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_login_at"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "alerts", "devices"
  add_foreign_key "alerts", "plants"
  add_foreign_key "devices", "plants"
  add_foreign_key "energy_readings", "plants"
end
