# Image
FROM php:8.0-fpm

# PS
RUN apt-get update && apt-get install -y procps

# Dependencies
RUN apt-get update

# Zip
RUN apt-get install -y libzip-dev zip && docker-php-ext-configure zip && docker-php-ext-install zip

# Utility tools
RUN apt-get install -y \
    git \
    nano \
    htop \
    vim

# Curl
RUN apt-get install -y libcurl3-dev curl && docker-php-ext-install curl

# ImageMagick
RUN apt-get install -y imagemagick && apt-get install -y --no-install-recommends libmagickwand-dev
RUN pecl install imagick && docker-php-ext-enable imagick

# PostgreSQL
RUN apt-get install -y libpq-dev && docker-php-ext-install pdo pdo_pgsql

# PHP GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# BC Math
RUN docker-php-ext-install \
    bcmath \
    sockets \
    opcache \
    intl \
    gd


# PHP Other extensions
RUN docker-php-ext-install exif && docker-php-ext-enable exif

# PHP Redis extension
RUN pecl install redis
RUN docker-php-ext-enable redis

# Composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer
RUN chmod 0755 /usr/bin/composer

# Composer require
RUN composer global require \
    laravel/installer \
    phpunit/phpunit

COPY composer.lock composer.json /var/www/html/
RUN composer install --no-scripts --no-autoloader

COPY . /var/www/html

# NPM & PM2
RUN apt-get install npm -y
RUN npm install pm2 -g

# ENV PATH
ENV PATH=~/.composer/vendor/bin:$PATH
ENV PATH=/var/www/bin:$PATH

# Composer keys
COPY ./docker/auth.json /root/.composer/auth.json

# Custom php.ini config
COPY ./docker/php.ini /usr/local/etc/php/php.ini

RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache

# Clean up
RUN apt-get clean
RUN apt-get -y autoremove
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up default directory
WORKDIR /var/www/html

# Expose port 9000 and start php-fpm server (for FastCGI Process Manager)
EXPOSE 9000
CMD ["php-fpm"]
