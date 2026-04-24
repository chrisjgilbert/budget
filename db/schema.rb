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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_070412) do
  create_table "fields", force: :cascade do |t|
    t.string "behavior", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.integer "month_id", null: false
    t.integer "position", default: 0, null: false
    t.boolean "reset_on_new", default: false, null: false
    t.string "section", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["month_id", "key"], name: "index_fields_on_month_id_and_key", unique: true
    t.index ["month_id"], name: "index_fields_on_month_id"
  end

  create_table "months", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year", "month"], name: "index_months_on_year_and_month", unique: true
  end

  add_foreign_key "fields", "months"
end
