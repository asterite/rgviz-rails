# -*- encoding: utf-8 -*-
# stub: rgviz-rails 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rgviz-rails".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ary Borenszweig".freeze]
  s.date = "2023-02-06"
  s.email = "aborenszweig@manas.com.ar".freeze
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze, "lib/rgviz_rails.rb".freeze, "lib/rgviz_rails/adapters/mysql_adapter.rb".freeze, "lib/rgviz_rails/adapters/postgresql_adapter.rb".freeze, "lib/rgviz_rails/adapters/sqlite_adapter.rb".freeze, "lib/rgviz_rails/executor.rb".freeze, "lib/rgviz_rails/init.rb".freeze, "lib/rgviz_rails/js_renderer.rb".freeze, "lib/rgviz_rails/parser.rb".freeze, "lib/rgviz_rails/tqx.rb".freeze, "lib/rgviz_rails/view_helper.rb".freeze, "rails/init.rb".freeze]
  s.homepage = "http://github.com/asterite/rgviz-rails".freeze
  s.rubygems_version = "3.3.26".freeze
  s.summary = "rgviz for rails".freeze

  s.installed_by_version = "3.3.26" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rgviz>.freeze, [">= 0.50"])
    s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rgviz>.freeze, [">= 0.50"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
  end
end
