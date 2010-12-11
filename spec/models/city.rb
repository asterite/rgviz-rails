class City < ActiveRecord::Base
  has_many :people
  belongs_to :country
end
