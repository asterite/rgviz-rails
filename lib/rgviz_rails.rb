require 'rgviz'
require 'rgviz_rails/init.rb'
require 'rgviz_rails/executor.rb'
require 'rgviz_rails/js_renderer.rb'
require 'rgviz_rails/tqx.rb'

class Rgviz::Parser
  def parse_time(string)
    Time.zone.parse string
  end

  def parse_date(string)
    parse_time(string).to_date
  end
end

module RgvizRails
end
