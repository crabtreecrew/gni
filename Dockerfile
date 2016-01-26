FROM ubuntu:14.04

RUN apt-get install -y software-properties-common && \
    apt-add-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y ruby1.8 rubygems1.8 ruby-switch git \
    zlib1g-dev liblzma-dev libxml2-dev libxslt-dev libmysqlclient-dev \
    imagemagick libmagickwand-dev supervisor && \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get install -qq -y nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    chown -R www-data:www-data /var/lib/nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ruby-switch --set ruby1.8
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
RUN bundle install --without development test

COPY . /app


# CMD ["unicorn", "-c", "/app/config/docker/files/unicorn.rb"]
CMD /usr/bin/supervisord
