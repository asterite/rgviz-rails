# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "rgviz_rails/version"

spec = Gem::Specification.new do |s|
  s.name = "rgviz-rails"
  s.version = RgvizRails::VERSION
  s.author = "Ary Borenszweig"
  s.email = "aborenszweig@manas.com.ar"
  s.homepage = "http://github.com/asterite/rgviz-rails"
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
    "rails/init.rb"
  ]
  s.add_dependency "rgviz"
  s.add_dependency "rails"
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README.rdoc"]
end
