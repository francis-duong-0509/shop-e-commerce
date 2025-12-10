FROM php:8.3-fpm-alpine

# Build arguments for cache optimization
ARG BUILDKIT_INLINE_CACHE=1

# Enable BuildKit for better caching
# syntax=docker/dockerfile:1

# Update Alpine repositories
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    supervisor \
    nginx \
    nodejs \
    npm \
    bash \
    mysql-client \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    autoconf \
    g++ \
    make \
    linux-headers

# Install PHP extensions with parallel builds
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        gd \
        zip \
        bcmath \
        intl \
        xml \
        mbstring \
        opcache \
        exif \
        pcntl \
        sockets \
    && docker-php-ext-enable opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Ensure www-data user exists with consistent UID/GID
RUN set -x \
    && addgroup -g 82 -S www-data 2>/dev/null || true \
    && adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true

# Create necessary directories
RUN mkdir -p /var/www/html \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /run/nginx \
    && mkdir -p /var/lib/nginx/tmp/client_body \
    && chown -R www-data:www-data /var/log/supervisor \
    && chown -R www-data:www-data /var/log/nginx \
    && chown -R www-data:www-data /var/cache/nginx \
    && chown -R www-data:www-data /run/nginx \
    && chown -R www-data:www-data /var/lib/nginx

# Set working directory
WORKDIR /var/www/html

# Copy only necessary files for runtime environment
# Note: Application code will be mounted via docker-compose volume
COPY composer.json composer.lock* ./

# Copy entrypoint script
COPY devops/local/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Skip Laravel post-install commands during build to avoid database connections
# These will be run in the entrypoint script when the container starts

# Set permissions for /var/www/html directory
# Note: storage and bootstrap/cache permissions will be handled by entrypoint.sh
RUN chown -R www-data:www-data /var/www/html

# Expose ports
EXPOSE 80

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]