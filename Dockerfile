# Maximum php version supported by Moodle is 8.1
FROM php:8.1-apache

# Set working directory
WORKDIR /var/www/html/moodle

# Install Moodle dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        unzip \
        rsync \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype-dev \
        libxml2-dev \
        libzip-dev \
        libonig-dev \
        mariadb-client \
        libicu-dev \
        zlib1g-dev \
        procps \
        libcurl4-openssl-dev \
        libsodium-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo \
        pdo_mysql \
        gd \
        zip \
        intl \
        opcache \
        curl \
        sodium && \
    a2enmod rewrite && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Moodle configuration
COPY ./moodle/moodle.ini /usr/local/etc/php/conf.d/moodle.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Xdebug config
ARG XDEBUG_PORT=9003
COPY ./moodle/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
RUN printf '\nxdebug.client_port=%s\n' ${XDEBUG_PORT} >> /usr/local/etc/php/conf.d/xdebug.ini

# Apache config
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
COPY ./moodle/000-moodle.conf /etc/apache2/sites-available/
RUN a2ensite 000-moodle.conf && a2dissite 000-default.conf
