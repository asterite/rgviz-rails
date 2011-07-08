spec = Gem::Specification.new do |s|
  s.name = "rgviz-rails"
  s.version = "0.48"
  s.author = "Ary Borenszweig"
  s.email = "aborenszweig@manas.com.ar"
  s.homepage = "http://code.google.com/p/rgviz-rails"
  s.platform = Gem::Platform::RUBY
  s.summary = "rgviz for rails"
  s.files = [
    "lib/rgviz_rails.rb",
    "lib/rgviz_rails/executor.rb",
    "lib/rgviz_rails/js_renderer.rb",
    "lib/rgviz_rails/tqx.rb",
    "lib/rgviz_rails/view_helper.rb",
    "lib/rgviz_rails/adapters/mysql_adapter.rb",
    "lib/rgviz_rails/adapters/postgresql_adapter.rb",
    "lib/rgviz_rails/adapters/sqlite_adapter.rb",
    "lib/rgviz_rails/init.rb",
    "rails/init.rb",
    "spec/blueprints.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/models/city.rb",
    "spec/models/country.rb",
    "spec/models/person.rb",
    "spec/rgviz/executor_spec.rb",
  ]
  s.add_dependency 'rgviz'
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README.rdoc"]
end
