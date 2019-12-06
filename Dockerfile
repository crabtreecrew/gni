FROM ubuntu:14.04.4

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-add-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y ruby2.1 ruby2.1-dev ruby-switch \
    openjdk-7-jdk curl zlib1g-dev liblzma-dev libxml2-dev \
    libxslt-dev libmysqlclient-dev supervisor build-essential nodejs && \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get install -qq -y nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    chown -R www-data:www-data /var/lib/nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV MYSQL_ROOT_HOST %

RUN ruby-switch --set ruby2.1
RUN echo 'gem: --no-rdoc --no-ri >> "$HOME/.gemrc"'

# Configure Bundler to install everything globally
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN gem install bundler -v 1.17.3 && \
    bundle config --global path "$GEM_HOME" && \
    bundle config --global bin "$GEM_HOME/bin" && \
    mkdir /app

WORKDIR /tmp

ENV BUNDLE_APP_CONFIG $GEM_HOME

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

WORKDIR /app

COPY . .

EXPOSE 3000

# This keeps the container running so we can execute commands manually to set up the databases
# and then run the startup.sh script
CMD tail -f /dev/null

# Currently, if we try to run this ENTRYPOINT it will fail because the databases can't be created.
# Normally this would be done by running: `bundle exec rake db:create:all`, but this doesn't work
# when the command is run from a different host than MySQL is running on (which is how we have it
# set up with docker-compose.yml). The workaround is to create the database manually.
# See: doc/dockerizing_notes.md
# ENTRYPOINT ["sh", "./config/docker/scripts/startup.sh"]
