require "spec_helper"

describe RgvizRails::Parser do
  describe :parse_time do
    before :all do
      @format = "%B %d, %Y %H:%M:%S"
    end
    
    # Provide a proxy for testing the otherwise protected method
    class RgvizRails::Parser
      def public_parse_time(time_string)
        parse_time(time_string)
      end
    end
    
    before :each do
      @parser = RgvizRails::Parser.new("select *")
    end
    
    context :default_time_zone do
      before :each do
        Time.zone = nil
      end
      
      it "parses a time string" do
        now = Time.now
        @parser.public_parse_time(now.strftime(@format)).to_i.should == now.to_i
      end
    end
    
    context :custom_time_zone do
      
      def parse_with_zone(time_zone)
        Time.zone = time_zone
        now = Time.now
        parsed = @parser.public_parse_time(now.strftime(@format))
        (now.to_i - parsed.to_i).should == Time.zone.utc_offset
      end
      
      it "parses a time string with the Pacific time zone" do
        parse_with_zone("Pacific Time (US & Canada)")
      end
      
      it "parses a time string with the Cairo time zone" do
        parse_with_zone("Cairo")
      end
      
      it "parses a string with the London time zone" do
        parse_with_zone("London")
      end
      
      it "parses a string with the Sydney time zone" do
        parse_with_zone("Sydney")
      end
      
      it "parses a string with the Central time zone" do
        parse_with_zone("Central Time (US & Canada)")
      end
    end
  end
end