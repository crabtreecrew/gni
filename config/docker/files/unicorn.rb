app_dir = "/app"
ENV["RACK_ENV"] = ENV["RAILS_ENV"] = "production"

working_directory app_dir

pid "#{app_dir}/tmp/unicorn.pid"

stderr_path "#{app_dir}/log/unicorn.stderr.log"
stdout_path "#{app_dir}/log/unicorn.stdout.log"

workers_num = ENV["GNI_UNICORN_WORKER_PROCESSES"].to_i
workers_num = 10 if worker_processes == 0

worker_processes workers_num

listen "/tmp/unicorn.sock", :backlog => 64
timeout 240
