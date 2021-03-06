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

ActiveRecord::Schema.define(:version => 20120804121702) do

  create_table "authentications", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "token"
    t.integer  "identity_id"
  end

  create_table "connections", :force => true do |t|
    t.integer  "id1"
    t.integer  "id2"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "link_type"
  end

  create_table "identities", :force => true do |t|
    t.string   "uid"
    t.integer  "provider_id"
    t.integer  "user_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "listings", :force => true do |t|
    t.integer  "user_id"
    t.string   "randomized_id"
    t.string   "title"
    t.string   "category"
    t.text     "body"
    t.string   "url"
    t.string   "embedded_trust_url"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "photos", :force => true do |t|
    t.integer  "listing_id"
    t.string   "file_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "ratings", :force => true do |t|
    t.integer  "listing_id"
    t.integer  "stars"
    t.integer  "rater_id"
    t.text     "rater_comment"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "storages", :force => true do |t|
    t.string   "uid"
    t.string   "auth_token"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "user_id"
    t.string   "provider"
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "trust_score"
    t.string   "email"
    t.string   "login"
    t.string   "password_digest"
    t.integer  "salt"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
