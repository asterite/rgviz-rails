require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  name { Faker::Name.name }
  number(:unique => false) { rand(100) + 1 }
  date { Date.parse("#{rand(40) + 1970}-#{rand(12) + 1}-#{rand(28) + 1}") }
end

City.blueprint do
  name
  country
end

Country.blueprint do
  name
end

Person.blueprint do
  name
  age { Sham::number }
  birthday { Sham::date }
  city
end
