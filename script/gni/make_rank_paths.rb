#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= 'development'
require File.expand_path('../../../config/environment', __FILE__)
batch = 1_000

db = NameString.connection
current_id = 0
max_id = db.select_value('select max(id) from name_strings')
db.execute("DROP TEMPORARY TABLE IF EXISTS `tmp_name_string_indices`")
db.execute("CREATE 
              TEMPORARY TABLE `tmp_name_string_indices` 
           LIKE `name_string_indices`")
while 1
  q = "select id from name_strings where id > %s limit %s"
  res = db.select_values(q % [current_id, batch])
  break if res.empty?
  current_id = res.last
  puts current_id 
  res.each do |name_string_id|
    data = db.select_rows("
      select 
        *
      from 
        name_string_indices
      where name_string_id = %s 
        and (classification_path_ids != '' 
             or classification_path_ids is not null)" % name_string_id)
    data.each do |row|
      taxon_ids = row[9].split('|')
      data_source_id = row[0]
      name_string_id = row[1]
      taxon_id = row[2]
      ranks = []
      taxon_ids.each do |path_taxon_id|
        q = "SELECT 
               rank
             FROM 
               name_string_indices
             WHERE
               data_source_id = %s
               AND name_string_id = %s
               AND taxon_id = '%s'" % 
             [name_string_id,
              data_source_id,
              path_taxon_id]
             require 'ruby-debug'; debugger
        rank = db.select_value(q)
        ranks[-1] = rank

      end
      ranks = ranks.join('|')
      row << ranks 
      db.execute("insert into 
                      name_string_indices
                      (%s)" % row.map { |r| db.quote(r) }.join(","))
    end
  end

end
  
