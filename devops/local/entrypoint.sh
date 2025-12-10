#!/bin/bash
set -e

# Error handling
trap 'echo "❌ Error occurred on line $LINENO. Exit code: $?" >&2' ERR

echo "🚀 Starting Local Environment Setup..."
echo "📍 Working directory: $(pwd)"
echo "📁 Checking for vendor directory..."

# Function to wait for a service
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=30
    local attempt=0

    echo "⏳ Waiting for $service_name to be ready..."

    while [ $attempt -lt $max_attempts ]; do
        if eval "$check_command" >/dev/null 2>&1; then
            echo "✅ $service_name is ready!"
            return 0
        fi

        attempt=$((attempt + 1))
        echo "   Attempt $attempt/$max_attempts..."
        sleep 2
    done

    echo "❌ $service_name failed to start after $max_attempts attempts"
    return 1
}

# Wait for MySQL
if [ ! -z "$DB_HOST" ]; then
    wait_for_service "MySQL" "mysqladmin ping -h$DB_HOST -uroot -p$DB_ROOT_PASSWORD --silent"
fi

# Check if vendor directory exists (in case of volume mount)
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "📦 Installing composer dependencies (volume mount detected)..."
    cd /var/www/html

    # Clean up any existing vendor directory
    if [ -d /var/www/html/vendor ]; then
        echo "🧹 Cleaning up existing vendor directory..."
        rm -rf /var/www/html/vendor
    fi

    # Keep composer.lock if it exists for faster install
    if [ -f /var/www/html/composer.lock ]; then
        echo "📄 Using existing composer.lock for consistent dependencies..."
    else
        echo "📄 No composer.lock found, will create new one..."
    fi

    echo "🔄 Running composer install..."
    COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist --optimize-autoloader || {
        echo "❌ Composer install failed with exit code $?"
        echo "🔄 Trying composer update instead..."
        COMPOSER_MEMORY_LIMIT=-1 composer update --no-interaction --prefer-dist --optimize-autoloader || {
            echo "❌ Composer update also failed with exit code $?"
            exit 1
        }
    }
    echo "✓ Composer dependencies installed"

    # Fix vendor permissions after install
    echo "🔐 Fixing vendor directory permissions..."
    chown -R www-data:www-data /var/www/html/vendor
    chmod -R 755 /var/www/html/vendor
fi

echo "🔧 Running Laravel setup commands..."

# Run composer post-autoload scripts now that database is available
echo "📦 Running composer post-autoload scripts..."
composer dump-autoload --optimize

# Discover packages
echo "🔍 Discovering packages..."
php artisan package:discover --ansi

# Generate application key if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Run migrations
echo "📊 Running database migrations..."
php artisan migrate --force || {
    echo "⚠️  Migration failed, but continuing..."
}

# Note: Database seeding should be run manually when needed
# Use: docker compose exec app php artisan db:seed

# Create storage symlink
echo "🔗 Creating storage symlink..."
php artisan storage:link --force

# Clear and restart queues
echo "🔄 Restarting queues..."
php artisan queue:restart

# Clear caches
echo "🧹 Clearing caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Set permissions
echo "🔐 Setting permissions..."

# Ensure storage subdirectories exist with correct permissions
mkdir -p /var/www/html/storage/{app,framework,logs}
mkdir -p /var/www/html/storage/framework/{cache,sessions,views}
mkdir -p /var/www/html/storage/app/public
mkdir -p /var/www/html/storage/app/modules

# Set ownership and permissions for storage
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache || true

# Fix modules permissions if directory exists
if [ -d /var/www/html/Modules ]; then
    echo "🔐 Fixing Modules directory permissions..."
    chown -R www-data:www-data /var/www/html/Modules
    chmod -R 775 /var/www/html/Modules
fi

# Fix public directory permissions for uploads
if [ -d /var/www/html/public/uploads ]; then
    chown -R www-data:www-data /var/www/html/public/uploads
    chmod -R 775 /var/www/html/public/uploads
fi

# Fix Vite hot file if it exists with wrong URL
if [ -f "/var/www/html/public/hot" ]; then
    HOT_CONTENT=$(cat /var/www/html/public/hot 2>/dev/null || echo "")
    if [[ "$HOT_CONTENT" == *"0.0.0.0"* ]]; then
        echo "🔥 Fixing Vite hot file URL..."
        echo "http://localhost:${DOCKER_VITE_PORT:-5109}" > /var/www/html/public/hot
        echo "✓ Hot file updated to use localhost:${DOCKER_VITE_PORT:-5109}"
    fi
fi

# Install Laravel Admin if applicable
if [ -f "/var/www/html/config/admin.php" ] && [ ! -d "/var/www/html/public/vendor/laravel-admin" ]; then
    echo "📦 Installing Laravel Admin assets..."
    php artisan vendor:publish --provider="Encore\\Admin\\AdminServiceProvider" || true
fi

# Create necessary directories for services
mkdir -p /var/log/supervisor /var/log/nginx /var/cache/nginx /run/nginx
chown -R www-data:www-data /var/log/supervisor /var/log/nginx
chmod -R 775 /var/log/supervisor /var/log/nginx

# Install npm dependencies if node_modules doesn't exist
if [ ! -d /var/www/html/node_modules ] || [ ! -f /var/www/html/node_modules/.package-lock.json ]; then
    echo "📦 Installing npm dependencies..."
    npm ci --prefer-offline --no-audit || npm install --no-audit
    echo "✓ NPM dependencies installed"
fi

# Run Laravel optimize command
echo "⚡ Optimizing application..."
php artisan optimize

# Verify all service connections
echo "🔍 Verifying service connections..."

# Database connection
echo "   🗄️  Database connection:"
if ! php artisan db:show --database=mysql 2>/dev/null; then
    echo "   ❌ Database connection failed"
    echo "   🔧 Check DB_HOST: $DB_HOST"
    echo "   🔧 Check DB_DATABASE: $DB_DATABASE"
    echo "   🔧 Check DB_USERNAME: $DB_USERNAME"
    echo "   🛑 Stopping all processes due to database connection failure"
    exit 1
fi
echo "   ✅ Database connection successful"

echo "✨ Setup complete!"

# Execute the command passed to the container
exec "$@"
