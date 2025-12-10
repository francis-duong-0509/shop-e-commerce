#!/bin/bash
set -e

# Output with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Data volume management helper functions
setup_data_directories() {
    local base_path="$1"
    shift
    local directories=("$@")

    for dir in "${directories[@]}"; do
        mkdir -p "${base_path}/${dir}" 2>/dev/null
    done
}

# create_safe_symlink() {
#     local source="$1"
#     local target="$2"
#
#     # Remove existing directory or broken symlink
#     if [ -d "$target" ] && [ ! -L "$target" ]; then
#         rm -rf "$target" 2>/dev/null
#     elif [ -L "$target" ]; then
#         # If symlink exists, remove it to recreate
#         rm -f "$target" 2>/dev/null
#     fi
#
#     # Create symlink
#     ln -sfn "$source" "$target" 2>/dev/null
# }

# Minimal output - only show errors
exec 2>&1

# Graceful shutdown handling
trap 'log "🛑 Received shutdown signal, stopping services gracefully..."; supervisorctl stop all; exit 0' SIGTERM SIGINT

log "🚀 Starting Prism Web Application container..."

# =============================================================================
# DATA VOLUME SETUP SECTION
# =============================================================================
# All /data directory setup and management consolidated here
#
# To add new persistent directories:
# 1. Add to setup_data_directories call below with appropriate base path
# 2. Use rsync to sync files instead of symlinks for better compatibility
# 3. Ensure proper permissions are set
#
# Current /data structure:
# /data/
# ├── storage/           # Laravel application data
# ├── bootstrap/cache/   # Laravel bootstrap cache
# ├── public/uploads/    # User uploads
# ├── system/logs/       # System service logs (nginx, php, supervisor)
# ├── backup/            # Application backups
# ├── temp/              # Temporary files
# └── config/            # Runtime configurations

log "💾 Setting up persistent data volume structure..."

# 1. System runtime directories (non-persistent)
log "   📁 Creating system runtime directories..."
mkdir -p /run/nginx /run/supervisord 2>/dev/null
mkdir -p /var/lib/nginx/tmp/{client_body,proxy,fastcgi,scgi,uwsgi} 2>/dev/null

# 2. Laravel application data structure in /data
log "   📂 Creating Laravel application data structure..."
setup_data_directories "/data" \
    "storage/app" \
    "storage/app/public" \
    "storage/framework/cache" \
    "storage/framework/sessions" \
    "storage/framework/views" \
    "storage/logs" \
    "bootstrap/cache" \
    "public/uploads"

# 2.1. Create specific directories for different upload types
log "   📁 Creating specific upload directories..."
setup_data_directories "/data/public/uploads" \
    "app/logo" \
    "certificates" \
    "ckeditor" \
    "file/candidate-requests" \
    "file/candidates" \
    "file/fast_applications" \
    "file/job-requests" \
    "headhunters/id_cards" \
    "headhunters/profile_pictures" \
    "images/candidates" \
    "images/company" \
    "images/job-category" \
    "images/job-test" \
    "images/post" \
    "images/post-category" \
    "images/professional_certificates" \
    "images/testimonial"

# Ensure storage/app/public exists specifically (critical for file uploads)
log "   📁 Ensuring storage/app/public directory exists..."
mkdir -p "/data/storage/app/public" 2>/dev/null

# 3. System service logs structure in /data
log "   📋 Creating system service logs structure..."
setup_data_directories "/data/system/logs" \
    "supervisor" \
    "nginx" \
    "php"

# 4. Future extensibility - additional data directories
log "   📦 Creating additional data directories..."
setup_data_directories "/data" \
    "backup" \
    "temp" \
    "config"

# 5. Ensure Laravel cache directories exist (critical for Dokploy)
log "   📁 Ensuring Laravel cache directories exist..."
mkdir -p /var/www/html/storage/framework/{cache,sessions,views} 2>/dev/null
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null

# 6. Set permissions for all /data directories
log "   🔐 Setting /data permissions..."
chown -R appuser:appuser /data 2>/dev/null
chmod -R 775 /data 2>/dev/null

# 7. Set system directory permissions
log "   🔒 Setting system directory permissions..."
chown -R appuser:appuser /run/supervisord 2>/dev/null
chown -R appuser:appuser /var/lib/nginx 2>/dev/null
chmod -R 755 /var/lib/nginx 2>/dev/null

# 7.1. Fix Nginx temp directory permissions for file uploads (secure 775 instead of 777)
log "   🔧 Setting secure permissions for Nginx temp directories..."
chown -R appuser:appuser /var/lib/nginx/tmp 2>/dev/null
chmod -R 775 /var/lib/nginx/tmp 2>/dev/null
log "   ✅ Nginx temp directories secured with 775 permissions"

# 8. Sync data from persistent storage (essential for file uploads)
log "   📁 Syncing data from persistent storage..."

# Handle existing directories - backup if they contain data before syncing
if [ -d "/var/www/html/storage" ] && [ ! -L "/var/www/html/storage" ]; then
    log "   📦 Backing up existing storage directory..."
    # Copy any existing files to persistent location
    rsync -av /var/www/html/storage/ /data/storage/ 2>/dev/null || true
fi

# Handle existing bootstrap/cache directory
if [ -d "/var/www/html/bootstrap/cache" ] && [ ! -L "/var/www/html/bootstrap/cache" ]; then
    log "   📦 Backing up existing bootstrap/cache directory..."
    # Copy any existing files to persistent location
    rsync -av /var/www/html/bootstrap/cache/ /data/bootstrap/cache/ 2>/dev/null || true
fi

# Handle existing public/uploads directory
if [ -d "/var/www/html/public/uploads" ] && [ ! -L "/var/www/html/public/uploads" ]; then
    log "   📦 Migrating existing public/uploads to persistent storage..."
    # Copy existing files to persistent location
    rsync -av /var/www/html/public/uploads/ /data/public/uploads/ 2>/dev/null || true
    log "   ✅ Static assets migrated to persistent storage"
fi

# Create Laravel storage structure first
log "   📁 Creating Laravel storage structure..."
mkdir -p /var/www/html/storage/{logs,framework/{cache/data,sessions,views},app/public} 2>/dev/null || true
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || true

# Sync data back from persistent storage (only if data exists)
log "   🔄 Syncing data from persistent storage to application directories..."
if [ -d "/data/storage" ] && [ "$(ls -A /data/storage 2>/dev/null)" ]; then
    rsync -av /data/storage/ /var/www/html/storage/ 2>/dev/null || true
fi
if [ -d "/data/bootstrap/cache" ] && [ "$(ls -A /data/bootstrap/cache 2>/dev/null)" ]; then
    rsync -av /data/bootstrap/cache/ /var/www/html/bootstrap/cache/ 2>/dev/null || true
fi
if [ -d "/data/public/uploads" ] && [ "$(ls -A /data/public/uploads 2>/dev/null)" ]; then
    rsync -av /data/public/uploads/ /var/www/html/public/uploads/ 2>/dev/null || true
fi

# Recreate storage structure after rsync (in case rsync overwrote)
mkdir -p /var/www/html/storage/{logs,framework/{cache/data,sessions,views},app/public} 2>/dev/null || true
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || true

# Fix permissions after rsync - use appuser for everything
log "   🔐 Fixing permissions after rsync..."
chown -R appuser:appuser /var/www/html/storage 2>/dev/null || true
chown -R appuser:appuser /var/www/html/bootstrap/cache 2>/dev/null || true
chown -R appuser:appuser /var/www/html/public/uploads 2>/dev/null || true
chmod -R 775 /var/www/html/storage 2>/dev/null || true
chmod -R 775 /var/www/html/bootstrap/cache 2>/dev/null || true

log "   ✅ Data sync and permission fix completed"

log "   ✅ /data volume setup completed"

# =============================================================================
# END DATA VOLUME SETUP SECTION
# =============================================================================

# Laravel setup
# Quick debug for Dokploy
log "🔍 Container starting in $(pwd)"
[ -d "vendor" ] && log "✅ Vendor exists" || log "⚠️ Vendor missing"
[ -f ".env" ] && log "✅ .env exists" || log "⚠️ .env missing"

# Check and auto-install vendor if missing (common on Dokploy)
if [ ! -d "/var/www/html/vendor" ]; then
    log "⚠️  Vendor not found (common on cloud deployments)"
    log "📦 Installing PHP dependencies..."

    # Check if composer exists
    if [ -f "/usr/bin/composer" ]; then
        COMPOSER_MEMORY_LIMIT=-1 composer install \
            --no-interaction \
            --no-scripts \
            --prefer-dist \
            --no-dev \
            --optimize-autoloader 2>&1 | tail -5

        # Generate autoload
        composer dump-autoload --optimize 2>/dev/null
        log "✅ Dependencies installed"
    else
        log "❌ Composer not found! Cannot install dependencies"
        exit 1
    fi
fi

# Now run package discovery
log "🎨 Discovering Laravel packages..."
if php artisan package:discover --ansi 2>&1 | grep -E "(Discovered|Package|INFO)" | head -10 | sed 's/^/   /'; then
    log "   ✅ Package discovery completed"
else
    log "⚠️  Package discovery had warnings, continuing..."
fi

# Load environment variables
log "🔧 Loading environment variables..."
# Check if .env file exists
if [ -f /var/www/html/.env ]; then
    # Parse and export each line manually to handle quotes properly
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        case "$key" in
            '#'*|'') continue ;;
        esac
        # Remove surrounding quotes from value if present
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        # Export the variable
        export "$key=$value"
    done < /var/www/html/.env
else
    log "⚠️  No .env file found"

    # Copy from .env.example if it exists
    if [ -f "/var/www/html/.env.example" ]; then
        log "📝 Creating .env from .env.example..."
        cp /var/www/html/.env.example /var/www/html/.env
        chown appuser:appuser /var/www/html/.env
        chmod 600 /var/www/html/.env
        log "✅ .env created from .env.example"

        # Override database credentials from Dokploy environment
        if [ -n "$DB_HOST" ]; then
            log "🔧 Updating database credentials from environment..."
            sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" /var/www/html/.env
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" /var/www/html/.env
            sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" /var/www/html/.env
            sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" /var/www/html/.env
            log "✅ Database credentials updated for Dokploy"
        fi
    else
        log "❌ .env.example not found, cannot create .env"
    fi
fi

# Set timezone if missing
if [ -z "$APP_TIMEZONE" ]; then
    export APP_TIMEZONE="Asia/Ho_Chi_Minh"
    echo "APP_TIMEZONE=Asia/Ho_Chi_Minh" >> /var/www/html/.env 2>/dev/null
    log "⏰ Set timezone to Asia/Ho_Chi_Minh"
fi

# Wait for MySQL to be fully ready
wait_for_mysql() {
    if [ -z "$DB_HOST" ]; then
        log "⚠️  No DB_HOST configured, skipping MySQL check"
        return 0
    fi

    log "🔌 Waiting for MySQL to be fully ready at ${DB_HOST}:${DB_PORT:-3306}..."
    log "   Using user: ${DB_USERNAME:-root}"

    local attempt=1
    local max_attempts=36
    local wait_time=5

    while [ $attempt -le $max_attempts ]; do
        # Try to connect to MySQL
        if timeout 10 mysql -h$DB_HOST -u${DB_USERNAME:-root} -p$DB_PASSWORD --connect-timeout=10 --skip-ssl -e "SELECT 1" >/dev/null 2>&1; then
            log "   ✅ MySQL is ready and accepting connections"
            return 0
        fi

        if [ $attempt -eq 1 ]; then
            log "   ⏳ MySQL not ready yet, will retry..."
        fi

        if [ $((attempt % 6)) -eq 0 ]; then
            log "   Still waiting for MySQL... (attempt ${attempt}/${max_attempts})"
        fi

        # Exponential backoff: increase wait time every 12 attempts
        if [ $((attempt % 12)) -eq 0 ] && [ $wait_time -lt 10 ]; then
            wait_time=$((wait_time + 2))
            log "   Increasing wait time to ${wait_time}s..."
        fi

        sleep $wait_time
        attempt=$((attempt + 1))
    done

    log "   ❌ MySQL connection failed after ${max_attempts} attempts (3 minutes)"
    log "   This might be a configuration issue or MySQL is taking too long to start"
    exit 1
}

# Check MySQL connection (now after environment is loaded)
wait_for_mysql

# Auto-import app.sql if exists and database is empty
SKIP_MIGRATIONS=false
SKIP_SEEDERS=false

if [ -f "/import/sql/app.sql" ]; then
    log "📦 Checking database status for app.sql import..."
    TABLE_COUNT=$(mysql -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE -e "SHOW TABLES;" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    if [ "$TABLE_COUNT" -le "1" ]; then
        log "📥 Found app.sql, importing complete database..."

        if mysql -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < /import/sql/app.sql 2>/dev/null; then
            log "✅ Database imported successfully from app.sql"

            # Skip migrations and seeders since we imported full database
            SKIP_MIGRATIONS=true
            SKIP_SEEDERS=true
        else
            log "⚠️  Failed to import app.sql, will run migrations instead"
        fi
    else
        log "📊 Database already has $TABLE_COUNT tables, skipping app.sql import"
    fi
fi

# Generate app key if missing
if ! grep -q "^APP_KEY=.*[^[:space:]]" /var/www/html/.env 2>/dev/null; then
    log "🔑 Generating application key..."
    php artisan key:generate --force --no-interaction >/dev/null 2>&1
fi

# Create storage symlink for public file access
log "🔗 Creating Laravel storage symlink..."
php artisan storage:link --force 2>&1 | grep -E "(linked|exists|created)" | head -3 | sed 's/^/   /'

# Verify the Laravel storage symlink points to persistent location
log "   🔍 Verifying Laravel storage symlink..."
if [ -L "/var/www/html/public/storage" ]; then
    STORAGE_TARGET=$(readlink /var/www/html/public/storage)
    log "      → /public/storage → $STORAGE_TARGET"

    # Check if it points to our persistent storage
    if [[ "$STORAGE_TARGET" == *"/data/storage/app/public"* ]] || [[ "$STORAGE_TARGET" == "../storage/app/public" ]]; then
        log "   ✅ Laravel storage symlink correctly points to persistent location"
    else
        log "   ⚠️ Laravel storage symlink may not point to persistent location"
        log "      Expected: ../storage/app/public (via /data/storage symlink)"
        log "      Actual: $STORAGE_TARGET"
    fi
else
    log "   ⚠️ Laravel storage symlink not found at /public/storage"
fi

# Database operations
if [ "$SKIP_MIGRATIONS" = "true" ]; then
    log "📊 Skipping migrations (database imported from app.sql)"
else
    log "📊 Running database migrations..."
    # Show full migration output for debugging
php artisan migrate --force 2>&1 | tee /tmp/migrate.log
MIGRATE_STATUS=${PIPESTATUS[0]}

if [ $MIGRATE_STATUS -ne 0 ]; then
    log "❌ Migration failed with exit code: $MIGRATE_STATUS"
    log "📋 Error details:"
    # Show last 30 lines of error
    tail -30 /tmp/migrate.log | sed 's/^/   /'

    # Also test basic connection
    log "🔍 Testing database connection..."
    php artisan db:show --database=mysql 2>&1 | head -10 | sed 's/^/   /'

    # Exit with failure
    exit 1
else
    log "✅ Database migrations completed successfully"
fi
fi

# Database seeding for development environment
if [ "$SKIP_SEEDERS" = "true" ]; then
    log "🌱 Skipping seeders (database imported from app.sql)"
elif [ "$APP_ENV" = "dev" ] || [ "$APP_ENV" = "local" ]; then
    log "🌱 Checking database seeders for development..."

    # Check if database has been fully seeded by checking the plans table
    # Plans table is created by MasterSeeder and indicates complete seeding
    PLANS_COUNT=$(mysql -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE -e "SELECT COUNT(*) FROM plans;" 2>/dev/null | tail -1 | tr -d ' ' | grep -o '[0-9]*' || echo "0")

    if [ "$PLANS_COUNT" = "0" ]; then
        log "   Database not fully seeded, running complete seeders..."
        php artisan db:seed --force 2>&1 | tee /tmp/seed.log | grep -E "(DONE|FAIL|ERROR|INFO)" | sed 's/^/   /' || true

        # Check if seeding was successful
        if grep -q "ERROR\|FAIL" /tmp/seed.log 2>/dev/null; then
            log "⚠️  Some seeders failed, but continuing..."
        else
            log "✅ Database seeders completed successfully"
        fi
    else
        log "   Database already seeded (plans: $PLANS_COUNT), skipping to avoid duplicates"
    fi
else
    log "📝 Database seeding is disabled for production safety"
    log "   For local development, use ./devops2/local/setup.sh"
fi

# Assets are now built at Docker image build time
log "📦 Frontend assets already built in Docker image"

# Clear caches and optimize
log "🧹 Clearing caches and optimizing..."
php artisan config:clear 2>&1 | grep -v "^$" | sed 's/^/   /'
php artisan route:clear 2>&1 | grep -v "^$" | sed 's/^/   /'
php artisan view:clear 2>&1 | grep -v "^$" | sed 's/^/   /'
php artisan cache:clear 2>&1 | grep -v "^$" | sed 's/^/   /'
php artisan optimize:clear 2>&1 | grep "Cached" | sed 's/^/   /'
php artisan queue:restart 2>&1 | grep -v "^$" | sed 's/^/   /'

# Verify database connection
log "✔️  Verifying final database connection..."
php artisan db:show --database=mysql 2>&1 | grep -E "(Database|Host|Port|Username|Tables)" | sed 's/^/   /'
[ ${PIPESTATUS[0]} -ne 0 ] && { log "❌ Database connection verification failed"; exit 1; }

# Final permission check before starting services
log "🔐 Final permission verification for session storage..."
chown -R appuser:appuser /var/www/html/storage 2>/dev/null || true
chmod -R 775 /var/www/html/storage/framework/{cache,sessions,views} 2>/dev/null || true

# Show session directory permissions for debugging
log "   📋 Session directory permissions:"
ls -la /var/www/html/storage/framework/sessions/ 2>/dev/null | head -5 | sed 's/^/      /' || log "      Session directory not found, will be created on first request"

# Final Laravel storage verification before starting services
log "📁 Final Laravel storage verification..."
mkdir -p /var/www/html/storage/{logs,framework/{cache/data,sessions,views},app/public} 2>/dev/null
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null
chown -R appuser:appuser /var/www/html/storage 2>/dev/null
chown -R appuser:appuser /var/www/html/bootstrap/cache 2>/dev/null
chmod -R 775 /var/www/html/storage 2>/dev/null
chmod -R 775 /var/www/html/bootstrap/cache 2>/dev/null

# Fix log file permissions before starting services
log "🔧 Fixing log file permissions..."
touch /data/system/logs/nginx/access.log /data/system/logs/nginx/error.log 2>/dev/null || true
chown appuser:appuser /data/system/logs/nginx/*.log 2>/dev/null || true
chown appuser:appuser /run/nginx 2>/dev/null || true
rm -f /run/nginx/nginx.pid 2>/dev/null || true

# Start supervisord
log "🎯 Starting Supervisor daemon..."
log "✨ Application ready! Starting web server and queue workers..."
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
