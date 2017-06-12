app_dir = "/var/www/app"
ENV["RACK_ENV"] = ENV["RAILS_ENV"] = "production"

working_directory app_dir

pid "#{app_dir}/tmp/unicorn.pid"

stderr_path "#{app_dir}/log/unicorn.stderr.log"
stdout_path "#{app_dir}/log/unicorn.stdout.log"

workers_num = ENV["GNI_UNICORN_WORKER_PROCESSES"].to_i
workers_num = 1 if workers_num == 0

worker_processes workers_num

listen 8080, tcp_nopush: true
timeout 240
