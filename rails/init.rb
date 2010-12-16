if Rails::VERSION::MAJOR == 2
  config.after_initialize do
    Rgviz._define_rgviz_class
  end
end
