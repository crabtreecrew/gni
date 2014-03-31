# encoding: utf-8
require 'csv'
require File.expand_path("../../config/environment", __FILE__)
unless [:development, :test, :production].include? Rails.env.to_sym
  puts 'Use: bundle exec rake db:seed RAILS_ENV=test|development|production'
  exit
end

class Seeder
  attr :env_dir, :common_dir

  def initialize
    @db = ActiveRecord::Base.connection
    @common_dir = File.join(File.dirname(__FILE__), 'csv')
    @env_dir = File.join(common_dir, Rails.env.to_s)
    @path = nil
  end

  def walk_path(path)
    run_migrations_msg = "\nBefore adding seeds run:\n"\
      "bundle exec rake db:migrate RAILS_ENV=%s\n\n" % Rails.env
    @path = path
    files = Dir.entries(path).map {|e| e.to_s}.select {|e| e.match /csv$/}
    begin
      files.each do |file|
        add_seeds(file)
      end
    rescue ActiveRecord::StatementInvalid
      raise run_migrations_msg
    end
  end

  private 
  
  def add_seeds(file)
    table = file.gsub(/\.csv/, '')
    data = get_data(table, file) 
    @db.execute("truncate table %s" % table) 
    @db.execute("insert ignore into %s values %s" % [table, data]) if data
  end

  def get_data(table, file)
    columns = @db.select_values("show columns from %s" % table)
    ca_index = columns.index("created_at")
    ua_index = columns.index("updated_at")
    csv_args = { col_sep: "\t", quote_char: 'ш' }
    data = CSV.open(File.join(@path, file), csv_args).map do |row|
      res = get_row(row, ca_index, ua_index)
      (columns.size - res.size).times { res << 'null' } 
      res.join(",")
    end rescue raise("Cannot load data from %s" % file)
    data.empty? ? nil : "(%s)" % data.join("), (")
  end

  def get_row(row, ca_index, ua_index)
    res = []
    row.each_with_index do |field, index|
      if [ca_index, ua_index].include? index
        res << 'now()'
      else
        field = field.match(%r|\\N|) ? 'null' : @db.quote(field)
        res << field
      end
    end
    res
  end

end

s = Seeder.new
s.walk_path(s.common_dir)
s.walk_path(s.env_dir)
puts "You added seeds data to %s tables" % Rails.env.upcase


__END__
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
  conf = Rails.configuration.database_configuration[Rails.env]
  host = conf['host']
  [nil, 'locahost', '127.0.0.1', '0.0.0.0'].include?(host)
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
