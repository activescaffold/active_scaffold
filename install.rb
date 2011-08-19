File.open(File.expand_path('../../../../config/initializers/active_scaffold.rb', __FILE__), 'w') do |f|
  f << "#ActiveSupport.on_load(:active_scaffold) { self.js_framework = :jquery }\n"
end
