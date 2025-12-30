#!/bin/bash
# Check admin web build status

echo "=== Checking Admin Web Build Status ==="
echo ""

# Check if build is running
if ps aux | grep -v grep | grep -q "docker build.*vanyatra-admin-web"; then
    echo "✓ Build is currently running..."
    echo ""
    echo "Latest build output:"
    tail -20 ~/admin_web/build.log
    echo ""
    echo "To monitor in real-time: tail -f ~/admin_web/build.log"
elif docker images | grep -q vanyatra-admin-web; then
    echo "✓ Build completed successfully!"
    echo ""
    docker images | grep vanyatra-admin-web
    echo ""
    echo "Ready to deploy. Run: ./deploy-admin-web.sh"
else
    echo "✗ Build not started or failed"
    echo ""
    echo "Last build output:"
    tail -30 ~/admin_web/build.log 2>/dev/null || echo "No build log found"
fi
