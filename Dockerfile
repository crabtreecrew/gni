FROM ubuntu:14.04.4
MAINTAINER Dmitry Mozzherin
ENV LAST_FULL_REBUILD 2016-03-06


RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-add-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y ruby2.1 ruby2.1-dev ruby-switch \
    curl redis-server zlib1g-dev liblzma-dev libxml2-dev \
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

RUN ruby-switch --set ruby2.1
RUN echo 'gem: --no-rdoc --no-ri >> "$HOME/.gemrc"'

# Configure Bundler to install everything globally
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN gem install bundler && \
    bundle config --global path "$GEM_HOME" && \
    bundle config --global bin "$GEM_HOME/bin" && \
    mkdir /app


COPY config/docker/files/nginx-sites.conf /etc/nginx/sites-enabled/default
COPY config/docker/files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /app

ENV BUNDLE_APP_CONFIG $GEM_HOME

COPY Gemfile /app/
COPY Gemfile.lock /app/
RUN bundle install

COPY . /app
RUN bundle exec rake assets:precompile RAILS_ENV=production

# CMD ["unicorn", "-c", "/app/config/docker/files/unicorn.rb"]
CMD /usr/bin/supervisord

