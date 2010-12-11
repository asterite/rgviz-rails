$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'spec'
require 'logger'

require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
#ActiveRecord::Base.establish_connection(:adapter => 'mysql', :database => 'rgviz_rails', :username => 'root', :password => '###')
#ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'rgviz_rails', :username => 'postgres', :password => '###', :host => '/var/run/postgresql/')

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
end

require File.dirname(__FILE__) + '/models/person'
require File.dirname(__FILE__) + '/models/city'
require File.dirname(__FILE__) + '/models/country'

require File.dirname(__FILE__) + '/blueprints'

require 'rgviz'
require 'rgviz_rails'

RAILS_ENV = 'test'

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.load_paths << File.dirname(__FILE__)
