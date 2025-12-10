#!/bin/bash

# Christian Faith Web Local Development Environment Startup Script
# This script sets up and runs the Laravel application in local development mode
#
# Environment Variables:
# - RUN_SEEDERS=true : Run database seeders after initial setup (default: false)
#
# Usage:
#   ./start-local.sh                    # Normal startup
#   RUN_SEEDERS=true ./start-local.sh  # Run with database seeders

set -e

echo "🚀 Starting ShopX Local Development Environment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if required template files exist
if [ ! -f .env.port ] || [ ! -f .env.example ]; then
    echo -e "${RED}❌ Missing required files: .env.port or .env.example${NC}"
    exit 1
fi

# Check if .env file exists in project root, if not create from local files
if [ ! -f ../../.env ]; then
    echo -e "${YELLOW}📝 Creating .env file from .env.port and .env.example...${NC}"
    # Combine .env.port and .env.example
    cat .env.port > ../../.env
    echo "" >> ../../.env  # Add blank line between files
    cat .env.example >> ../../.env
    echo -e "${GREEN}✅ .env file created. Please update database credentials if needed.${NC}"
else
    echo -e "${YELLOW}📝 Overwriting .env file from .env.port and .env.example...${NC}"
    # Combine .env.port and .env.example
    cat .env.port > ../../.env
    echo "" >> ../../.env  # Add blank line between files
    cat .env.example >> ../../.env
    echo -e "${GREEN}✅ .env file updated from local environment.${NC}"
fi

# Check if .env file exists in devops/local, if not create from .env.port and .env.example
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating devops/local/.env file from .env.port and .env.example...${NC}"
    # Combine .env.port and .env.example
    cat .env.port > .env
    echo "" >> .env  # Add blank line between files
    cat .env.example >> .env
    echo -e "${GREEN}✅ devops/local/.env file created.${NC}"
fi

echo -e "${BLUE}🐳 Building and starting Docker containers...${NC}"

# Build and start services using local configuration
docker compose up -d --build

echo -e "${BLUE}⏳ Waiting for services to be healthy...${NC}"

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
MYSQL_WAIT_COUNT=0
MYSQL_MAX_WAIT=30
until docker compose exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    MYSQL_WAIT_COUNT=$((MYSQL_WAIT_COUNT + 1))
    if [ $MYSQL_WAIT_COUNT -gt $MYSQL_MAX_WAIT ]; then
        echo -e "${RED}❌ MySQL failed to start after ${MYSQL_MAX_WAIT} attempts${NC}"
        echo -e "${YELLOW}💡 Check logs with: docker compose logs mysql${NC}"
        exit 1
    fi
    echo -n "."
    sleep 3
done
echo ""

# Node is now part of the app container, no separate check needed

echo -e "${GREEN}✅ Services are ready!${NC}"

# Run local development setup commands
echo -e "${BLUE}🔧 Setting up Laravel for local development...${NC}"

# Wait for app container to be ready
echo "Waiting for app container to be ready..."
APP_WAIT_COUNT=0
APP_MAX_WAIT=30
until docker compose exec app php --version >/dev/null 2>&1; do
    APP_WAIT_COUNT=$((APP_WAIT_COUNT + 1))
    if [ $APP_WAIT_COUNT -gt $APP_MAX_WAIT ]; then
        echo -e "${RED}❌ App container failed to start after ${APP_MAX_WAIT} attempts${NC}"
        echo -e "${YELLOW}💡 Check logs with: docker compose logs app${NC}"
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""

# Wait for composer dependencies to be installed by entrypoint
echo -e "${BLUE}⏳ Waiting for composer dependencies...${NC}"
COMPOSER_WAIT_COUNT=0
COMPOSER_MAX_WAIT=60
until docker compose exec app test -f /var/www/html/vendor/autoload.php 2>/dev/null; do
    COMPOSER_WAIT_COUNT=$((COMPOSER_WAIT_COUNT + 1))
    if [ $COMPOSER_WAIT_COUNT -gt $COMPOSER_MAX_WAIT ]; then
        echo -e "${RED}❌ Composer dependencies failed to install after ${COMPOSER_MAX_WAIT} attempts${NC}"
        echo -e "${YELLOW}💡 Check logs with: docker compose logs app${NC}"
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""
echo -e "${GREEN}✅ Composer dependencies ready!${NC}"

# Generate app key if needed
docker compose exec app php artisan key:generate --force

# Load environment variables from devops/local/.env
if [ -f .env ]; then
    # Export variables, ignoring comments and empty lines
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${YELLOW}⚠️  Warning: devops/local/.env file not found. Using default values.${NC}"
fi

# Check if database already has data (to avoid re-importing)
DB_EXISTS=$(docker compose exec mysql mysql -uroot -p"${DB_ROOT_PASSWORD:-root_password}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_DATABASE:-christianfaith_db}';" -s -N 2>/dev/null || echo "0")

if [ "$DB_EXISTS" -eq "0" ]; then
    echo -e "${BLUE}📦 Importing database from app.sql...${NC}"
    # Import the database if it exists
    if [ -f ../common/configs/app.sql ]; then
        docker compose exec -T mysql mysql -uroot -p"${DB_ROOT_PASSWORD:-root_password}" "${DB_DATABASE:-christianfaith_db}" < ../common/configs/app.sql
        echo -e "${GREEN}✅ Database imported successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  No app.sql file found, running migrations instead...${NC}"
        # Run migrations if no SQL file exists
        docker compose exec app php artisan migrate --force
    fi

    # Optional: Run database seeders for fresh installations
    if [ "${RUN_SEEDERS:-false}" = "true" ]; then
        echo -e "${BLUE}🌱 Running database seeders...${NC}"
        docker compose exec app php artisan db:seed --force
        echo -e "${GREEN}✅ Database seeded successfully${NC}"
    fi
else
    echo -e "${GREEN}✅ Database already exists, skipping import${NC}"
fi

# Create storage link
docker compose exec app php artisan storage:link

# Clear and cache for development
docker compose exec app php artisan config:clear
docker compose exec app php artisan route:clear
docker compose exec app php artisan view:clear

# Build frontend assets
echo -e "${BLUE}📦 Building frontend assets...${NC}"
# Node is now integrated in app container, wait for Vite to be ready
echo "Waiting for Vite dev server to start..."
sleep 5

# Wait for all services to be healthy
echo -e "${BLUE}🔍 Waiting for all services to be healthy...${NC}"
WAIT_ATTEMPTS=0
WAIT_MAX_ATTEMPTS=30

while [ $WAIT_ATTEMPTS -lt $WAIT_MAX_ATTEMPTS ]; do
    # Check if app container is healthy (includes nginx and node)
    if docker compose ps app | grep -q "(healthy)"; then
        echo -e "${GREEN}✅ All services are healthy and ready!${NC}"
        break
    else
        WAIT_ATTEMPTS=$((WAIT_ATTEMPTS + 1))
        if [ $WAIT_ATTEMPTS -eq $WAIT_MAX_ATTEMPTS ]; then
            echo -e "${YELLOW}⚠️  Some services may not be fully ready yet${NC}"
            echo -e "${YELLOW}💡 Check status with: docker compose ps${NC}"
        else
            echo "   Waiting for services (attempt $WAIT_ATTEMPTS/$WAIT_MAX_ATTEMPTS)..."
            sleep 2
        fi
    fi
done

echo -e "${GREEN}🎉 Local development environment is ready!${NC}"
echo -e "${BLUE}📱 Application URLs:${NC}"
echo -e "   Web: ${GREEN}http://localhost:${DOCKER_NGINX_PORT:-5100}${NC}"
echo -e "   Admin: ${GREEN}http://localhost:${DOCKER_NGINX_PORT:-5100}/admin${NC}"
echo -e "   phpMyAdmin: ${GREEN}http://localhost:${DOCKER_PHPMYADMIN_PORT:-5102}${NC}"
echo -e ""
echo -e "${BLUE}🔌 Direct connections:${NC}"
echo -e "   MySQL: ${GREEN}localhost:${DOCKER_MYSQL_PORT:-5101}${NC}"
echo -e "   Redis: ${GREEN}localhost:${DOCKER_REDIS_PORT:-5103}${NC}"

echo -e "${YELLOW}💡 Useful commands:${NC}"
echo -e "   View logs: ${BLUE}docker compose logs -f app${NC}"
echo -e "   Shell access: ${BLUE}docker compose exec app bash${NC}"
echo -e "   Stop services: ${BLUE}docker compose down${NC}"
echo -e "   Restart: ${BLUE}docker compose restart app${NC}"
echo -e "   View Vite logs: ${BLUE}docker compose exec app supervisorctl tail -f vite${NC}"
echo -e "   View nginx logs: ${BLUE}docker compose exec app supervisorctl tail -f nginx${NC}"

echo -e "${GREEN}✨ Happy coding!${NC}"
