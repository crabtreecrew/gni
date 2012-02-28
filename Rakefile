#!/usr/bin/env rake

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'escape'
require 'resque/tasks'

Gni::Application.load_tasks

task(:default).clear
task :default => [:spec, :cucumber]

task "resque:setup" => :environment do
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
    system(Escape.shell_command([Rails.root.join('script', 'solr'), 'stop']))
  end
end
