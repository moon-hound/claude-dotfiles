#!/bin/bash
# Deploy Personal Assistant with health check and rollback

set -e

# Set version from git (used by Sentry, logs)
export VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "📋 Version: $VERSION"

BACKUP_TAG="backup-$(date +%s)"

echo "🚀 Starting deployment..."

# Tag current version as backup
echo "📦 Tagging current version as backup..."
docker tag personal-assistant:latest personal-assistant:$BACKUP_TAG || true

# Build new version
echo "🔨 Building new version..."
docker build -t personal-assistant:latest .

# Stop current container
echo "⏹️  Stopping current container..."
docker-compose down || true

# Start new container
echo "▶️  Starting new container..."
docker-compose up -d

# Wait for health check
echo "🏥 Waiting for health check..."
for i in {1..30}; do
    if docker inspect personal-assistant --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
        echo "✅ Deploy successful - health check passed"
        exit 0
    fi
    echo "   Attempt $i/30..."
    sleep 2
done

# Health check failed - rollback
echo "❌ Health check failed - rolling back..."
docker-compose down
docker tag personal-assistant:$BACKUP_TAG personal-assistant:latest
docker-compose up -d

echo "🔄 Rolled back to previous version"
exit 1
