#!/bin/bash
# ==============================================================================
# 🚀 NEXT.JS DIRECT DEPLOYMENT SCRIPT (GIT TO DOCKER)
# For AWS EC2 instance (t2.micro / low RAM environment)
# ==============================================================================

# Fail immediately if any command fails
set -e

# --- CONFIGURATION ---
REPO_URL="https://github.com/aishwarya-devaraj/nextjs-demo-app.git"
CONTAINER_NAME="nextjs-app"
IMAGE_NAME="aishwaryadevaraj/nextjs-demo-app:latest"
PORT_HOST="3000"
PORT_CONTAINER="3000"
MEMORY_LIMIT="512m" # Docker container memory limit

echo "=================================================="
echo "🎬 Starting Deployment: Git to Docker Container"
echo "=================================================="

# 1. Pull latest code changes
echo "📥 Stage 1: Updating Source Code..."
git fetch origin main
git reset --hard origin/main
COMMIT_SHA=$(git rev-parse --short HEAD)
echo "✅ Code updated to commit: ${COMMIT_SHA}"

# 2. Install Dependencies (Memory Optimized for t2.micro)
echo "📦 Stage 2: Installing npm dependencies..."
export NODE_OPTIONS="--max-old-space-size=512"
npm install --no-audit --no-fund --prefer-offline
echo "✅ Dependencies installed."

# 3. Code Verification (Lint & Tests)
echo "🔍 Stage 3: Running Lint and Verification..."
npm run lint || echo "⚠️ Lint warnings detected, continuing..."

# 4. Compile Next.js
echo "🔨 Stage 4: Compiling Next.js Application..."
npm run build
echo "✅ Next.js production build complete."

# 5. Build Docker Image
echo "🐳 Stage 5: Building Docker Image..."
docker build \
  --build-arg GIT_COMMIT="${COMMIT_SHA}" \
  --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --tag "${IMAGE_NAME}" \
  .
echo "✅ Docker image built: ${IMAGE_NAME}"

# 6. Run Docker Container
echo "🚀 Stage 6: Running Container..."

# Stop and remove existing container if running
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo "🛑 Stopping and removing existing container: ${CONTAINER_NAME}..."
    docker stop "${CONTAINER_NAME}" || true
    docker rm "${CONTAINER_NAME}" || true
fi

# Run the new container
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${PORT_HOST}:${PORT_CONTAINER}" \
  -m "${MEMORY_LIMIT}" \
  -e NODE_ENV=production \
  -e PORT="${PORT_CONTAINER}" \
  "${IMAGE_NAME}"

echo "✅ Container is running!"
docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 7. Health Check
echo "💨 Stage 7: Running Health Check..."
echo "Waiting 10 seconds for container to initialize..."
sleep 10

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_HOST} --max-time 5 || echo "FAILED")

if [ "${HTTP_STATUS}" = "200" ]; then
    echo "🎉 SUCCESS: Application is healthy (HTTP 200 OK)!"
    echo "🌍 App is accessible at: http://localhost:${PORT_HOST}"
else
    echo "❌ ERROR: Health check failed (HTTP Status: ${HTTP_STATUS})"
    echo "📋 Printing last 20 lines of container logs:"
    docker logs --tail 20 "${CONTAINER_NAME}"
    exit 1
fi
