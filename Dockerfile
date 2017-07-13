FROM php:5.6-fpm
MAINTAINER Alex Ho "mralexho@gmail.com"

RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng12-dev \
        zip \
        unzip \
        zlib1g-dev \

  # nodejs
  && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
  && apt-get install -y nodejs \
  && apt-get clean\
  && apt-get autoremove \
  && rm -r /var/lib/apt/lists/* \

  # composer
  && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
  && rm -f /tmp/composer-setup.* \

  # composer parallel install
  && composer global require hirak/prestissimo:^0.3 \

  && docker-php-source extract \

  && docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \

  && NPROC=$(getconf _NPROCESSORS_ONLN) \

  && docker-php-ext-install -j${NPROC} gd \
        mcrypt \
        mysql \
        opcache \
        pdo_mysql \

  && pecl install \
        apcu-4.0.11 \
        memcached-2.2.0 \
        uploadprogress \

  && docker-php-ext-enable \
        apcu \
        memcached \
        uploadprogress \

  && docker-php-source delete

# Fix bug https://github.com/npm/npm/issues/9863
RUN cd $(npm root -g)/npm \
    && npm install fs-extra \
    && sed -i -e s/graceful-fs/fs-extra/ -e s/fs\.rename/fs.move/ ./lib/utils/rename.js

# Install NPM globally
RUN /usr/bin/npm install --global npm

# add composer global bin to PATH
ENV PATH /root/.composer/vendor/bin:$PATH