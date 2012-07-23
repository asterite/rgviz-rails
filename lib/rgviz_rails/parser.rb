module RgvizRails
  class Parser < Rgviz::Parser
    def self.parse(string)
      new(string).parse
    end
    
  protected
  
    def parse_time(time_string)
      time = Time.parse(time_string)
      
      # Honor the user's time zone if possible. We add the offset instead of using
      # Time.zone.parse because we do not want a TimeWithZone object. TimeWithZone is not
      # formatted as UTC when its used in ActiveRecord. We want the UTC
      # (or system time zone time) time for the given local time.
      if Time.zone
        time -= Time.zone.utc_offset.seconds
      end
      
      time
    end
  end
end