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

ActiveRecord::Schema[8.0].define(version: 2025_06_13_232000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "tiger.postgis_tiger_geocoder"
  enable_extension "topology.postgis_topology"

  create_table "city_syncs", force: :cascade do |t|
    t.string "state"
    t.string "city_name"
    t.string "gnis"
    t.string "meta_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "name"
    t.string "geoid"
    t.string "state"
    t.string "type"
    t.string "ocd_ids", array: true
    t.geometry "geom", limit: {srid: 4326, type: "geometry"}
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["geoid"], name: "index_municipalities_on_geoid"
    t.index ["ocd_ids"], name: "index_municipalities_on_ocd_ids", using: :gin
  end

  create_table "representatives", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "municipality_id"
    t.jsonb "data", default: {}, null: false
    t.index ["municipality_id"], name: "index_representatives_on_municipality_id"
  end
end
