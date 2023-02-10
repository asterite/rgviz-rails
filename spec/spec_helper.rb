$:.unshift(File.dirname(__FILE__) + "/../lib")

require "rubygems"
require "logger"
require "rails/all"
require "active_record"
require 'active_support/all'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
#ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "rgviz_rails", :username => "root", :password => "")
#ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database => "rgviz_rails", :username => "postgres", :password => "###", :host => "/var/run/postgresql/")

ActiveRecord::Schema.define do
  create_table "cities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "country_id"
  end

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.integer  "age"
    t.date     "birthday"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id"
  end

  create_table "foos", :force => true do |t|
  end

  create_table "foo_bars", :force => true do |t|
    t.integer "foo_id"
  end
end

require File.dirname(__FILE__) + "/models/person"
require File.dirname(__FILE__) + "/models/city"
require File.dirname(__FILE__) + "/models/country"
require File.dirname(__FILE__) + "/models/foo"
require File.dirname(__FILE__) + "/models/foo_bar"

require File.dirname(__FILE__) + "/blueprints"

require "rgviz"
require "rgviz_rails"

RAILS_ENV = "test"
