module Rgviz
  module JsRenderer
    def self.render(table, tqx)
      response_handler = tqx['responseHandler']
      req_id = tqx['reqId']
      version = tqx['version']
      "#{response_handler}({reqId:'#{req_id}',status:'ok',version:'#{version}',table:#{table.to_json}});"
    end
    
    def self.render_error(reason, message, tqx)
      reason = reason.gsub("'", "\\'")
      message = message.gsub("'", "\\'")
      response_handler = tqx['responseHandler']
      req_id = tqx['reqId']
      version = tqx['version']
      "#{response_handler}({reqId:'#{req_id}',status:'error',version:'#{version}',errors:[{reason:'#{reason}', message:'#{message}'}]});"
    end
  end
end
