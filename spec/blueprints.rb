require 'machinist/active_record'
require 'faker'

name  = Faker::Name.name
number = rand(100) + 1
date =  Date.parse("#{rand(40) + 1970}-#{rand(12) + 1}-#{rand(28) + 1}")

City.blueprint do
  name {name}
  country
end

Country.blueprint do
  name {name}
end

Person.blueprint do
  name {name}
  age {number}
  birthday {date}
  city
end
