# This automatically reads the REDIS_URL from the environment variables specified for the `app`
# service in docker-compose.yml
$redis ||= Redis.new
