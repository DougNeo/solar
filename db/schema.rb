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

ActiveRecord::Schema[8.0].define(version: 2024_11_17_061542) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "injected_energies", force: :cascade do |t|
    t.date "date"
    t.decimal "energy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plants", force: :cascade do |t|
    t.integer "plant_id"
    t.string "name"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "address"
    t.float "installed_capacity"
    t.datetime "start_operating_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
