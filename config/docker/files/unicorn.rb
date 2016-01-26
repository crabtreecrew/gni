app_dir = "/app"
ENV["RACK_ENV"] = ENV["RAILS_ENV"] = "production"

working_directory app_dir

pid "#{app_dir}/tmp/unicorn.pid"

stderr_path "#{app_dir}/log/unicorn.stderr.log"
stdout_path "#{app_dir}/log/unicorn.stdout.log"

worker_processes = ENV["GNI_UNICORN_WORKER_PROCESSES"].to_i
worker_processes = 10 if worker_processes == 0

# listen 8080, :tcp_nopush => true
listen "/tmp/unicorn.sock", :backlog => 64
timeout 240
