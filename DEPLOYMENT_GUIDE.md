# VanYatra Web Apps Deployment Guide

## Overview
This guide covers deploying both Admin Dashboard and Passenger App (web browser version) to your Azure VM server.

## Architecture
```
Azure VM (57.159.31.172)
├── Nginx (Port 80) - Web Server
│   ├── /var/www/admin - Admin Dashboard
│   └── /var/www/passenger - Passenger Web App
├── Backend API (Port 8000) - ASP.NET Core
├── SQL Server (Port 1433) - Database
└── Docker Containers
```

## Prerequisites

### Local Machine
- Flutter SDK 3.24.0 or higher
- SSH access to Azure VM
- SSH key: `server/ride_sharing_application/akhileshallewar880-key.pem`

### Azure VM
- Ubuntu Server
- Docker (already installed)
- Nginx (will be installed automatically)
- Ports 80, 8000, 1433 accessible

## Deployment Options

### Option 1: Automated CI/CD (Recommended for Production)

GitHub Actions will automatically deploy when you push changes to `main` branch.

#### Setup Steps:

1. **Add GitHub Secrets**
   - Go to GitHub Repository → Settings → Secrets and variables → Actions
   - Add these secrets:
     ```
     AZURE_VM_HOST = 57.159.31.172
     AZURE_VM_USERNAME = akhileshallewar880
     AZURE_VM_SSH_KEY = <contents of akhileshallewar880-key.pem>
     ```

2. **Initial Setup on Server**
   ```bash
   # Run this once to setup nginx
   ./deploy.sh all
   ```

3. **Automatic Deployments**
   - Push to `main` branch
   - Changes in `admin_web/` trigger admin deployment
   - Changes in `mobile/` trigger passenger deployment

### Option 2: Manual Deployment (Quick Testing)

Use the deployment script for immediate deployment:

```bash
# Make script executable
chmod +x deploy.sh

# Deploy both apps
./deploy.sh all

# Deploy only admin
./deploy.sh admin

# Deploy only passenger
./deploy.sh passenger
```

## Server Configuration

### Backend API CORS Configuration

Update `server/ride_sharing_application/appsettings.json`:

```json
{
  "Cors": {
    "AllowedOrigins": [
      "http://57.159.31.172",
      "http://admin.vanyatra.com",
      "http://passenger.vanyatra.com"
    ]
  }
}
```

Restart the backend container:
```bash
ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172
docker restart vanyatra-server
```

### Nginx Configuration

The `nginx.conf` file configures:
- Admin Dashboard on default route
- Passenger App on separate route
- API proxy from `/api/` to `localhost:8000/api/`
- Static asset caching
- Gzip compression
- Security headers

### Accessing the Apps

#### Using IP Address (Default)
- **Admin Dashboard**: `http://57.159.31.172/`
- **Passenger App**: `http://57.159.31.172/` (configure subdomain)
- **API**: `http://57.159.31.172:8000/api/`

#### Using Custom Domains (Optional)
1. Add DNS records pointing to `57.159.31.172`:
   - `admin.vanyatra.com` → A record
   - `passenger.vanyatra.com` → A record

2. Update nginx config with your domains

3. Setup SSL (optional but recommended):
   ```bash
   ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172
   sudo apt-get install certbot python3-certbot-nginx
   sudo certbot --nginx -d admin.vanyatra.com -d passenger.vanyatra.com
   ```

## Environment Configuration

### Admin Web App

Create `admin_web/lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://57.159.31.172:8000',
  );
}
```

### Passenger Web App

Create `mobile/lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://57.159.31.172:8000',
  );
}
```

## Build Commands

### Local Development Build
```bash
# Admin
cd admin_web
flutter build web --release --web-renderer canvaskit

# Passenger
cd mobile
flutter build web --release --web-renderer auto
```

### Production Build with Environment Variables
```bash
# Admin
flutter build web --release --web-renderer canvaskit \
  --dart-define=API_BASE_URL=http://57.159.31.172:8000

# Passenger
flutter build web --release --web-renderer auto \
  --dart-define=API_BASE_URL=http://57.159.31.172:8000
```

## Testing Deployment

### Smoke Tests

1. **Check Nginx Status**
   ```bash
   ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172
   sudo systemctl status nginx
   sudo nginx -t
   ```

2. **Check Web Apps**
   ```bash
   # Admin
   curl -I http://57.159.31.172/
   
   # Test API proxy
   curl http://57.159.31.172/api/health
   ```

3. **Browser Tests**
   - Open `http://57.159.31.172/` in browser
   - Verify assets load (check browser console)
   - Test login flow
   - Test API calls (check Network tab)

### Common Issues

#### 502 Bad Gateway
- Backend API not running: `docker ps | grep vanyatra-server`
- Restart: `docker restart vanyatra-server`

#### 404 Not Found on Refresh
- Nginx not configured for SPA routing
- Check `/etc/nginx/sites-available/vanyatra` has `try_files $uri $uri/ /index.html;`

#### CORS Errors
- Update backend CORS configuration
- Restart backend container
- Clear browser cache

#### Assets Not Loading
- Check file permissions: `ls -la /var/www/admin/`
- Should be owned by `www-data:www-data`
- Fix: `sudo chown -R www-data:www-data /var/www/admin /var/www/passenger`

## Monitoring

### Nginx Logs
```bash
ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Application Logs
```bash
# Backend
docker logs -f vanyatra-server

# Nginx
journalctl -u nginx -f
```

## Rollback

### Manual Rollback
```bash
# Redeploy previous version
git checkout <previous-commit>
./deploy.sh all
```

### CI/CD Rollback
- Revert the commit in GitHub
- Push to main branch
- Workflows will auto-deploy

## Security Checklist

- [ ] Change default SQL Server password
- [ ] Configure firewall rules (ufw)
- [ ] Setup SSL/TLS certificates
- [ ] Enable HTTPS redirect
- [ ] Configure rate limiting in nginx
- [ ] Setup monitoring and alerts
- [ ] Regular security updates
- [ ] Backup strategy implemented

## Next Steps

1. **SSL/TLS Setup**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

2. **Configure Firewall**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 22/tcp
   sudo ufw enable
   ```

3. **Setup Monitoring**
   - Configure Application Insights
   - Setup uptime monitoring
   - Configure log aggregation

4. **Performance Optimization**
   - Enable HTTP/2 in nginx
   - Configure CDN for static assets
   - Implement caching strategy

## Support

For issues or questions:
- Check logs: `sudo journalctl -u nginx -f`
- Verify container status: `docker ps`
- Test API: `curl http://localhost:8000/api/health`
