require "rgviz_rails/view_helper"
# includes the view helper to ActionView::Base
ActionView::Base.send(:include, Rgviz::ViewHelper)

module Rgviz
  def self._define_rgviz_class
    ::ActionController::Base.module_eval do
      def render_with_rgviz(*args, &block)
        if args.length == 1 && args[0].kind_of?(Hash)
          hash = args.first
          case hash[:rgviz]
          when nil then render_without_rgviz *args, &block
          else
            model = hash[:rgviz]
            conditions = hash[:conditions]
            virtual_columns = hash[:virtual_columns]
            query = params[:tq] || 'select *'
            tqx = params[:tqx] || ''

            tqx = Rgviz::Tqx.parse(tqx)

            begin
              options = {}
              options[:conditions] = conditions if conditions
              options[:virtual_columns] = virtual_columns if virtual_columns

              table = if model.is_a?(Class) && model < ActiveRecord::Base
                        Rgviz::Executor.new(model).execute query, options
                      elsif model.respond_to? :execute
                        model.execute query, options
                      elsif model.is_a? Rgviz::Table
                        model
                      else
                        raise "The argument to render :rgviz => ... must extend from ActiveRecord::Base, respond to execute or be an Rgviz::Table"
                      end

              yield table if block_given?

              case tqx['out']
              when 'json'
                render_without_rgviz :text => Rgviz::JsRenderer.render(table, tqx)
              when 'html'
                render_without_rgviz :text => Rgviz::HtmlRenderer.render(table)
              when 'csv'
                csv_output = Rgviz::CsvRenderer.render(table)
                if tqx['outFileName']
                  send_data csv_output, :filename => tqx['outFileName'], :type => 'text/csv'
                else
                  render_without_rgviz :text => csv_output
                end
              else
                render_without_rgviz :text => Rgviz::JsRenderer.render_error('not_supported', "Unsupported output type: #{out}", tqx)
              end
            rescue Exception => e
              case tqx['out']
              when 'json'
                render_without_rgviz :text => Rgviz::JsRenderer.render_error('invalid_query', e.message, tqx)
              when 'html'
                render_without_rgviz :text => "<b>Error:</b> #{e.message}"
              when 'csv'
                render_without_rgviz :text => "Error: #{e.message}"
              else
                render_without_rgviz :text => "<b>Unsupported output type:</b> #{out}"
              end
            end
          end
        else
          render_without_rgviz *args, &block
        end
      end
      alias_method_chain :render, :rgviz
    end
  end
end

if Rails::VERSION::MAJOR > 2
  class Railtie < Rails::Railtie
    initializer "define rgviz class" do
      Rgviz._define_rgviz_class
    end
  end
end
