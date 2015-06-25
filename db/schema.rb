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

ActiveRecord::Schema.define(version: 20150624224201) do

  create_table "edges", force: :cascade do |t|
    t.integer  "parent_id"
    t.integer  "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "edges", ["child_id"], name: "index_edges_on_child_id"
  add_index "edges", ["parent_id"], name: "index_edges_on_parent_id"

  create_table "programs", force: :cascade do |t|
    t.string   "name"
    t.integer  "requirement_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "programs", ["requirement_id"], name: "index_programs_on_requirement_id"

  create_table "requirements", force: :cascade do |t|
    t.string   "name"
    t.string   "min_grade"
    t.integer  "hours"
    t.integer  "take"
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
