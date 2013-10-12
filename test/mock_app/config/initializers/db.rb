stdout = $stdout
#$stdout = StringIO.new # suppress output while building the schema
load File.join(Rails.root, 'db', 'schema.rb')
$stdout = stdout
