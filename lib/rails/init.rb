require "rgviz_rails/view_helper"
# includes the view helper to ActionView::Base
ActionView::Base.send(:include, Rgviz::ViewHelper)

config.after_initialize do
  class ::ActionController::Base
    alias_method :original_render, :render
    def render(*args, &block)
      if args.length == 1 && args[0].kind_of?(Hash)
        hash = args.first 
        case hash[:rgviz]
        when nil then original_render *args, &block
        else
          model = hash[:rgviz]
          conditions = hash[:conditions]
          extensions = hash[:extensions]
          query = params[:tq]
          tqx = params[:tqx] || ''
          
          tqx = Rgviz::Tqx.parse(tqx)
          
          begin
            executor = Rgviz::Executor.new model, query
            options = {}
            options[:conditions] = conditions if conditions
            options[:extensions] = extensions if extensions
            table = executor.execute options
            
            yield table if block_given?
            
            case tqx['out']
            when 'json'
              original_render :text => Rgviz::JsRenderer.render(table, tqx)
            when 'html'
              original_render :text => Rgviz::HtmlRenderer.render(table)
            when 'csv'
              csv_output = Rgviz::CsvRenderer.render(table)
              if tqx['outFileName']
                send_data csv_output, :filename => tqx['outFileName'], :type => 'text/csv'
              else
                original_render :text => csv_output
              end
            else
              original_render :text => Rgviz::JsRenderer.render_error('not_supported', "Unsupported output type: #{out}", tqx)
            end
          rescue ParseException => e
            case tqx['out']
            when 'json'
              original_render :text => Rgviz::JsRenderer.render_error('invalid_query', e.message, tqx)
            when 'html'
              original_render :text => "<b>Error:</b> #{e.message}"
            when 'csv'
              original_render :text => "Error: #{e.message}"
            else
              original_render :text => "<b>Unsupported output type:</b> #{out}"
            end
          end
        end
      else
        original_render *args, &block
      end
    end
  end
end
