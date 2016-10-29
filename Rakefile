#!/usr/bin/env rake

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'escape'

Gni::Application.load_tasks

task(:default).clear
task :default => :spec

task :spec => 'db:seed'

namespace :db do
  desc "dumps tables from the environment to csv files"
  task :seedup => :environment do
    ENV["RAILS_ENV"] ||= 'development'
    csv_dir = Rails.root.join("db", "seed", ENV["RAILS_ENV"]).to_s
    shared_tables = Rails.root.join("db", "seed").entries.map {|e| e.to_s}.select {|e| e.match /csv$/}.map {|e| e.gsub(/\.csv$/, '')}
    shared_tables << "schema_migrations"
    db = ActiveRecord::Base.connection
    db.tables.each do |table|
      count = db.select_value("select count(*) from #{table}")
      if !shared_tables.include?(table) && count > 0
        file = "#{table}.csv"
        FileUtils.rm file if File.exists? file
        db.execute("select * into outfile '#{file}' from #{table}")
      end
    end
  end

  desc "adds records to a data_source from a file"
  task :addnames => :environment do
    ENV["RAILS_ENV"] ||= 'development'
    puts "Data are read from spec/files/addnames.csv, already saved data will not be overriden"
    CSV.open(Rails.root.join("spec", "files", "addnames.csv").to_s).each_with_index do |row, i|
      #assume order of 'data_source, name_string, taxon_id'
      next if i == 0
      name_string = NameString.find_or_create_by_name(row[1])
      index = NameStringIndex.where(:name_string_id => name_string.id, :data_source_id => row[0], :taxon_id => row[2])
      NameStringIndex.create(:name_string_id => name_string.id, :data_source_id => row[0], :taxon_id => row[2]) if index.empty?
    end
  end
end

namespace :solr do
  def run_command(command_type)
    port = Gni::Config.solr_url.match(/^.*:(\d+)/)[1]
    home = Rails.root.join('solr', 'multicore').to_s
    command = [Rails.root.join('script', 'solr').to_s, command_type, '--', '-p', port, '-s', home]
    system(Escape.shell_command(command))
  end

  desc 'start solr server instance in the background'
  task :start => :environment do
    puts "** Starting Bakground Solr instance **"
    run_command('start')
  end

  desc 'start solr server instance in the foreground'
  task :run => :environment do
    puts "** Starting Foreground Solr instance **"
    run_command('run')
  end

  desc 'stop solr instance'
  task :stop => :environment do
    puts "** Stopping Background Solr instance **"
    system(Escape.shell_command([Rails.root.join('script', 'solr').to_s, 'stop']))
  end

  desc 'build solr data'
  task :build => :environment do
    puts "** Rebuilding solr indices **"
    system(Escape.shell_command([Rails.root.join('script', 'gni', 'solr_import.rb').to_s]))
  end

  desc 'clear solr data'
  task :clear => :environment do
    puts "** Deleting solr data **"
    Gni::SolrIngest.new(Gni::SolrCoreCanonicalForm.new).delete_all
  end
end
