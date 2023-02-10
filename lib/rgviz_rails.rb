require "rgviz_rails/init"
require "rgviz_rails/executor"
require "rgviz_rails/js_renderer"
require "rgviz_rails/tqx"
require "rgviz_rails/parser"

module RgvizRails
  def self.date(date)
    def date.as_json(options = {})
      self
    end
    def date.encode_json(*)
      month = strftime("%m").to_i - 1
      "Date(#{strftime("%Y,#{month},%d")})"
    end
    date
  end

  def self.datetime(time)
    def time.as_json(*)
      self
    end
    def time.encode_json(*)
      month = strftime("%m").to_i - 1
      "Date(#{strftime("%Y,#{month},%d,%H,%M,%S")})"
    end
    time
  end

  def self.time_of_day(time)
    def time.as_json(*)
      self
    end
    def time.encode_json(*)
      "Date(#{strftime('0,0,0,%H,%M,%S')})"
    end
    time
  end

  def self.inherits_from_active_record(obj)
    (obj.is_a?(Class) && obj < ActiveRecord::Base) || obj.is_a?(ActiveRecord::Relation)
  end
end
