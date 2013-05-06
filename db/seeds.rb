#!/usr/bin/env ruby
# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), "../config/environment"))

class Seeder
  attr :common_dir, :env_dir

  def initialize
    @env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'].to_s : 'development'
    @db = NameString.connection
    @common_dir = File.expand_path(File.join(File.dirname(__FILE__), 'csv'))
    @env_dir = File.join(common_dir, @env)
    @path = nil
  end

  def walk_path(path)
    @path = path
    files = Dir.entries(path).map {|e| e.to_s}.select {|e| e.match /csv$/}
    files.each do |file|
      table = file.gsub(/\.csv/, '')
      data = get_data(table, file)
      puts "Repopulating %s for %s environment" % [table, @env]
      ["truncate table %s" % table,
       "insert into %s values %s" % [table, data]].each do |q|
        @db.execute(q)
      end if data
      puts table unless data
    end
  end

  private

  def get_data(table, file)
    columns = @db.select_values("show columns from %s" % table)
    ca_index = columns.index("created_at")
    ua_index = columns.index("updated_at")
    csv_args = {:col_sep => "\t"}
    data = CSV.open(File.join(@path, file), csv_args).map do |row|
      res = get_row(row, ca_index, ua_index)
      (columns.size - res.size).times { res << 'null' }
      res.join(",")
    end #rescue []
    data.empty? ? nil : "(%s)" % data.join("), (")
  end

  def get_row(row, ca_index, ua_index)
    res = []
    row.each_with_index do |field, index|
      if [ca_index, ua_index].include? index
        res << 'now()'
      else
        res << @db.quote(field)
      end
    end
    res
  end

end

s = Seeder.new

s.walk_path(s.common_dir)
s.walk_path(s.env_dir)


