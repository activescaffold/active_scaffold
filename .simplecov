SimpleCov.start do
  add_filter 'test'
  track_files '{app,lib}/**/*.rb'
end if ENV['CI']
