# ✅ VanYatra Web Apps Deployment - COMPLETE

## Deployment Summary

Successfully deployed both Admin Dashboard and Passenger Web App to Azure VM (57.159.31.172).

## Deployed Applications

### 🎯 Admin Dashboard
- **Port**: 80 (HTTP)
- **Location**: `/var/www/admin`
- **Local Access**: http://localhost/ (from server)
- **Public Access**: http://57.159.31.172/ (after Azure NSG configuration)

### 📱 Passenger Web App  
- **Port**: 81 (HTTP)
- **Location**: `/var/www/passenger`
- **Local Access**: http://localhost:81/ (from server)
- **Public Access**: http://57.159.31.172:81/ (after Azure NSG configuration)

### 🔌 Backend API
- **Port**: 8000
- **Proxy**: `/api/` routes to `localhost:8000/api/`
- **CORS**: Configured to allow all origins

## ⚠️ REQUIRED: Azure Network Security Group Configuration

The apps are deployed and working on the server, but **ports 80 and 81 need to be opened** in Azure NSG:

### Steps to Open Ports:

1. **Login to Azure Portal**: https://portal.azure.com

2. **Navigate to Your VM**:
   - Search for "vanyatraVm" or your VM name
   - Go to **Networking** → **Network Settings**

3. **Add Inbound Port Rules**:

   **Rule 1: HTTP (Port 80) - Admin Dashboard**
   ```
   Name: AllowHTTP
   Priority: 100
   Source: Any
   Source Port Ranges: *
   Destination: Any
   Service: HTTP
   Destination Port Ranges: 80
   Protocol: TCP
   Action: Allow
   ```

   **Rule 2: Custom (Port 81) - Passenger App**
   ```
   Name: AllowPort81
   Priority: 110
   Source: Any
   Source Port Ranges: *
   Destination: Any
   Service: Custom
   Destination Port Ranges: 81
   Protocol: TCP
   Action: Allow
   ```

4. **Save and Wait** (~1-2 minutes for rules to apply)

### Verify Azure NSG Rules:
```bash
# From your local machine, test after opening ports:
curl -I http://57.159.31.172/
curl -I http://57.159.31.172:81/
```

## CI/CD Setup

### GitHub Actions Workflows Created:
- `.github/workflows/deploy-admin-web.yml` - Auto-deploy admin on push to main
- `.github/workflows/deploy-passenger-web.yml` - Auto-deploy passenger on push to main

### Setup GitHub Secrets:

Go to: **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:
```
AZURE_VM_HOST = 57.159.31.172
AZURE_VM_USERNAME = akhileshallewar880
AZURE_VM_SSH_KEY = <paste contents of akhileshallewar880-key.pem>
```

### Manual Deployment (Alternative):

Use the deployment script:
```bash
# Deploy both apps
./deploy.sh all

# Deploy only admin
./deploy.sh admin

# Deploy only passenger
./deploy.sh passenger
```

## Server Configuration

### Nginx Configuration
- **Config File**: `/etc/nginx/sites-available/vanyatra`
- **Symlink**: `/etc/nginx/sites-enabled/vanyatra`
- **Status**: ✅ Active and running

### Nginx Commands:
```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Environment Configuration

### Admin Web: `admin_web/lib/config/environment.dart`
```dart
class Environment {
  static const String apiBaseUrl = 'http://57.159.31.172:8000';
  static String get apiUrl => '/api/v1';  // Uses nginx proxy
}
```

### Passenger Web: `mobile/lib/config/environment.dart`
```dart
class Environment {
  static const String apiBaseUrl = 'http://57.159.31.172:8000';
  static String get apiUrl => '/api/v1';  // Uses nginx proxy
}
```

## Testing

### Local Testing (from server):
```bash
ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172

# Test admin
curl -I http://localhost/

# Test passenger
curl -I http://localhost:81/

# Test API proxy
curl http://localhost/api/v1/health
```

### Remote Testing (after Azure NSG config):
```bash
# Test admin from your machine
curl -I http://57.159.31.172/

# Test passenger from your machine
curl -I http://57.159.31.172:81/

# Test in browser
open http://57.159.31.172/       # Admin Dashboard
open http://57.159.31.172:81/    # Passenger App
```

## Build Information

### Admin Web Build:
- **Framework**: Flutter 3.24.0
- **Renderer**: CanvasKit
- **Build Size**: ~3MB (main.dart.js)
- **Build Time**: ~23s

### Passenger Web Build:
- **Framework**: Flutter 3.24.0
- **Renderer**: Auto (adaptive)
- **Build Size**: ~3.8MB (main.dart.js)
- **Build Time**: ~26s

## File Structure on Server

```
/var/www/
├── admin/
│   ├── index.html
│   ├── main.dart.js
│   ├── flutter.js
│   ├── assets/
│   └── canvaskit/
└── passenger/
    ├── index.html
    ├── main.dart.js
    ├── flutter.js
    ├── assets/
    ├── icons/
    └── canvaskit/
```

## Troubleshooting

### Issue: Cannot access apps from browser

**Solution**: Open ports 80 and 81 in Azure NSG (see steps above)

### Issue: 502 Bad Gateway on /api/ requests

**Solution**: Check backend container is running:
```bash
docker ps | grep vanyatra-server
docker restart vanyatra-server
```

### Issue: 404 on page refresh

**Solution**: This is fixed in nginx config with `try_files $uri $uri/ /index.html;`

### Issue: Assets not loading (CORS errors)

**Solution**: Backend CORS is already configured to allow all origins. If issue persists:
```bash
docker restart vanyatra-server
```

### Issue: Changes not reflecting after deployment

**Solution**: Clear browser cache or hard refresh (Ctrl+Shift+R / Cmd+Shift+R)

## Monitoring

### Check Application Status:
```bash
# Check nginx
sudo systemctl status nginx

# Check listening ports
sudo ss -tlnp | grep -E ":80|:81|:8000"

# Check backend container
docker ps --filter name=vanyatra

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View backend logs
docker logs -f vanyatra-server
```

### Performance Monitoring:
- Nginx access logs: `/var/log/nginx/access.log`
- Nginx error logs: `/var/log/nginx/error.log`
- Backend logs: `docker logs vanyatra-server`

## Security Considerations

### Current Setup:
- ✅ HTTP (unencrypted) on ports 80 and 81
- ✅ CORS enabled for all origins
- ✅ Security headers configured (X-Frame-Options, X-XSS-Protection)
- ⚠️ No SSL/TLS (HTTPS not configured)
- ⚠️ No authentication for static content

### Recommended Next Steps:
1. **Setup SSL/TLS**: Use Let's Encrypt for free SSL certificates
2. **Configure Firewall**: Restrict access to known IPs if possible
3. **Add Authentication**: Consider adding basic auth for admin dashboard
4. **Enable Rate Limiting**: Prevent abuse and DDoS attacks
5. **Setup Monitoring**: Configure uptime monitoring and alerts

## Next Steps

### Immediate:
1. ✅ **Open Azure NSG ports 80 and 81** (REQUIRED for public access)
2. Test applications in browser
3. Setup GitHub secrets for CI/CD

### Short-term:
1. Configure custom domain names (optional)
2. Setup SSL/TLS certificates (recommended)
3. Configure monitoring and alerts
4. Test GitHub Actions workflows

### Long-term:
1. Setup CDN for static assets
2. Implement caching strategy
3. Configure automatic backups
4. Setup staging environment
5. Implement blue-green deployment

## Support

### Quick Commands:

```bash
# Redeploy everything
./deploy.sh all

# Check all services
ssh akhileshallewar880@57.159.31.172 'docker ps && sudo systemctl status nginx'

# View all logs
ssh akhileshallewar880@57.159.31.172 'sudo tail -50 /var/log/nginx/error.log && docker logs --tail 50 vanyatra-server'
```

### Files Created:
- ✅ `.github/workflows/deploy-admin-web.yml`
- ✅ `.github/workflows/deploy-passenger-web.yml`
- ✅ `nginx.conf`
- ✅ `deploy.sh`
- ✅ `DEPLOYMENT_GUIDE.md`
- ✅ `admin_web/lib/config/environment.dart`
- ✅ `mobile/lib/config/environment.dart`

---

**Status**: ✅ Deployment Complete - Awaiting Azure NSG Configuration

**Last Updated**: December 30, 2025
