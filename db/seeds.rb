# This file should contain all the record creation needed to seed the
# database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside
# the db with db:setup).
#
# to create csv files use "select * from table_name into outfile
# 'csv_file_name'"
# TODO: create rake db:seed:dump
#

def localhost?
  conf = Rails.configuration.database_configuration(Rails.env)
  host = conf['host']
  host && !['locahost', '127.0.0.1', '0.0.0.0'].include?(host)
end

def load_csv(dir, file)
  puts "Adding data to table %s" % file[0...-4]
  NameString.connection.execute("truncate %s" % file[0...-4])

  #hack to get around a bug in mysql2 on os x
  local= !!(RUBY_PLATFORM =~ /darwin/ || localhost?) ? '' : 'local'

  NameString.connection.execute("
    load data %s infile '%s'
    into table %s
    set created_at = now(), updated_at = now()
    " % [local, File.join(dir, file), file[0...-4]])
end

puts "Preloading data..."

csv_dir     = File.join(Rails.root, 'db', 'csv').to_s
env_csv_dir = File.join(csv_dir, Rails.env).to_s

[csv_dir, env_csv_dir].each do |dir|
  Dir.entries(dir).each do |file|
    load_csv(dir, file) if file[-4..-1] == ".csv"
  end
end
