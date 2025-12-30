#!/bin/bash
# Deploy admin web container

set -e

echo "=== Deploying Vanyatra Admin Web ==="

# Check if image exists
if ! docker images | grep -q vanyatra-admin-web; then
    echo "Error: Docker image 'vanyatra-admin-web' not found."
    echo "Please build the image first: docker build -t vanyatra-admin-web ."
    exit 1
fi

# Stop and remove existing container if running
if docker ps -a | grep -q vanyatra-admin; then
    echo "Stopping existing admin container..."
    docker stop vanyatra-admin 2>/dev/null || true
    docker rm vanyatra-admin 2>/dev/null || true
fi

# Run the admin web container
echo "Starting admin web container..."
docker run -d \
  --name vanyatra-admin \
  --network vanyatra-network \
  -p 3000:80 \
  --restart unless-stopped \
  vanyatra-admin-web

echo ""
echo "=== Admin Web Deployed Successfully ==="
echo "Admin web is now accessible at: http://57.159.31.172:3000"
echo ""
echo "Login credentials:"
echo "Email: admin@vanyatra.com"
echo "Password: Admin@123"
echo ""
echo "To view logs: docker logs -f vanyatra-admin"
echo "To stop: docker stop vanyatra-admin"
