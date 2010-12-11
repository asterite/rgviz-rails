module Rgviz
  module Tqx
    def self.parse(tqx)
      tqx ||= ''
      pieces = tqx.split ';'
      
      map = {
        'reqId' => '0', 
        'version' => '0.6', 
        'responseHandler' => 'google.visualization.Query.setResponse',
        'out' => 'json'
        }
        
      pieces.each do |p|
        key_value = p.split ':'
        map[key_value[0]] = key_value[1] if key_value.length == 2
      end
      
      map
    end
  end
end
