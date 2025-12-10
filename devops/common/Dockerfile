# Stage 1: Build dependencies and assets
FROM php:8.3-fpm-alpine AS builder

# Build arguments for environment-specific builds
ARG ENV_TYPE=prod

# System setup for building
RUN apk update && apk upgrade && \
    apk add --no-cache \
    git curl bash nodejs npm \
    libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev \
    icu-dev libxml2-dev oniguruma-dev \
    autoconf g++ make linux-headers \
    dpkg-dev dpkg file re2c pkgconfig

# PHP extensions for building
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql gd zip bcmath intl xml mbstring opcache exif pcntl sockets && \
    pecl install redis && \
    docker-php-ext-enable redis

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy package files first for better caching
COPY package*.json ./
COPY composer.json composer.lock ./

# Install PHP dependencies (conditional dev dependencies based on ENV_TYPE)
RUN if [ "$ENV_TYPE" = "dev" ]; then \
        echo "Installing with dev dependencies for development environment..."; \
        COMPOSER_MEMORY_LIMIT=-1 composer install \
            --no-interaction --no-scripts --prefer-dist -q; \
    else \
        echo "Installing production dependencies only..."; \
        COMPOSER_MEMORY_LIMIT=-1 composer install \
            --no-interaction --no-scripts --prefer-dist --no-dev -q; \
    fi

# Copy application files (node_modules and vendor excluded by .dockerignore)
COPY . .

# Complete composer setup and package discovery
RUN composer dump-autoload --optimize -q && \
    php artisan package:discover --ansi || true

# Install Node dependencies and build assets
RUN npm install && \
    npm run build && \
    rm -rf node_modules

# Stage 2: Production image
FROM php:8.3-fpm-alpine

# Build arguments
ARG ENV_TYPE=prod

# System setup
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl bash netcat-openbsd nodejs npm \
    libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev \
    zip unzip supervisor nginx mysql-client mariadb-connector-c \
    icu-dev libxml2-dev oniguruma-dev su-exec linux-headers \
    autoconf g++ make dpkg-dev dpkg file re2c pkgconfig

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql gd zip bcmath intl xml mbstring opcache exif pcntl sockets && \
    docker-php-ext-enable opcache && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    # Clean up
    rm -rf /tmp/pear /var/cache/apk/*

# Copy composer binary for runtime
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# User and directories
RUN adduser -D -u 1000 -g 1000 appuser && \
    mkdir -p /var/www/html /var/log/nginx /var/log/supervisor /data \
    /var/cache/nginx /run/nginx /run/supervisord \
    /var/lib/nginx/tmp/{client_body,proxy,fastcgi,scgi,uwsgi} \
    /var/lib/nginx/logs /usr/local/var/log /usr/local/var/run && \
    chown -R appuser:appuser /var/www/html /var/log/nginx \
    /var/log/supervisor /var/cache/nginx /run/nginx /run/supervisord /data && \
    chown -R appuser:appuser /var/lib/nginx /usr/local/var/log /usr/local/var/run && \
    chmod -R 775 /var/lib/nginx && \
    chmod -R 775 /data

WORKDIR /var/www/html

# Copy built application from builder stage
COPY --from=builder --chown=appuser:appuser /var/www/html .

# Environment file will be mounted from docker-compose
COPY --chown=appuser:appuser devops/common/.env .env

# Copy configuration files
COPY devops/common/configs/nginx.conf /etc/nginx/nginx.conf
COPY devops/common/configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY devops/common/configs/php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy PHP config based on environment type
COPY devops/common/configs/php-${ENV_TYPE}.ini /usr/local/etc/php/php.ini

# Create Laravel cache directories and fix asset permissions
RUN mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache \
    storage/app/livewire-tmp storage/app/public && \
    chmod -R 775 storage bootstrap/cache && \
    chown -R appuser:appuser public/build 2>/dev/null || true && \
    mkdir -p /data/system/logs/nginx && \
    chown -R appuser:appuser /data 2>/dev/null || true && \
    # Create public/uploads directory (will be populated via docker cp)
    mkdir -p public/uploads && \
    chown -R appuser:appuser public/uploads && \
    chmod -R 775 public/uploads

# Entrypoint script
COPY devops/common/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Environment variables
ENV DOCKER_BUILDKIT=1
ENV ENV_TYPE=${ENV_TYPE}

# Volume for persistent data
VOLUME ["/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80

# Use STOPSIGNAL for graceful shutdown
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
