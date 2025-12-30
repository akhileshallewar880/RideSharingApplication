#!/bin/bash
# VanYatra Web Apps Deployment Script
# Usage: ./deploy.sh [admin|passenger|all]

set -e

SERVER_USER="akhileshallewar880"
SERVER_HOST="57.159.31.172"
SSH_KEY="server/ride_sharing_application/akhileshallewar880-key.pem"

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_RESET='\033[0m'

log_info() {
    echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}❌ $1${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}"
}

# Function to build admin web
build_admin() {
    log_info "Building Admin Web..."
    cd admin_web
    flutter pub get
    flutter build web --release --web-renderer canvaskit
    cd ..
    log_success "Admin web built successfully"
}

# Function to build passenger web
build_passenger() {
    log_info "Building Passenger Web..."
    cd mobile
    flutter pub get
    flutter build web --release --web-renderer auto
    cd ..
    log_success "Passenger web built successfully"
}

# Function to deploy admin web
deploy_admin() {
    log_info "Deploying Admin Web to server..."
    
    # Create tarball
    cd admin_web/build
    tar -czf admin-web.tar.gz web/
    
    # Upload to server
    scp -i ../../$SSH_KEY admin-web.tar.gz $SERVER_USER@$SERVER_HOST:/tmp/
    
    # Extract and deploy on server
    ssh -i ../../$SSH_KEY $SERVER_USER@$SERVER_HOST << 'EOF'
        sudo mkdir -p /var/www/admin
        sudo tar -xzf /tmp/admin-web.tar.gz -C /var/www/admin --strip-components=1
        sudo chown -R www-data:www-data /var/www/admin
        rm /tmp/admin-web.tar.gz
EOF
    
    # Clean up local tarball
    rm admin-web.tar.gz
    cd ../..
    
    log_success "Admin web deployed successfully"
}

# Function to deploy passenger web
deploy_passenger() {
    log_info "Deploying Passenger Web to server..."
    
    # Create tarball
    cd mobile/build
    tar -czf passenger-web.tar.gz web/
    
    # Upload to server
    scp -i ../../$SSH_KEY passenger-web.tar.gz $SERVER_USER@$SERVER_HOST:/tmp/
    
    # Extract and deploy on server
    ssh -i ../../$SSH_KEY $SERVER_USER@$SERVER_HOST << 'EOF'
        sudo mkdir -p /var/www/passenger
        sudo tar -xzf /tmp/passenger-web.tar.gz -C /var/www/passenger --strip-components=1
        sudo chown -R www-data:www-data /var/www/passenger
        rm /tmp/passenger-web.tar.gz
EOF
    
    # Clean up local tarball
    rm passenger-web.tar.gz
    cd ../..
    
    log_success "Passenger web deployed successfully"
}

# Function to setup nginx
setup_nginx() {
    log_info "Setting up Nginx configuration..."
    
    # Upload nginx config
    scp -i $SSH_KEY nginx.conf $SERVER_USER@$SERVER_HOST:/tmp/vanyatra-nginx.conf
    
    # Configure nginx on server
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST << 'EOF'
        # Install nginx if not present
        if ! command -v nginx &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y nginx
        fi
        
        # Copy config
        sudo cp /tmp/vanyatra-nginx.conf /etc/nginx/sites-available/vanyatra
        
        # Enable site
        sudo ln -sf /etc/nginx/sites-available/vanyatra /etc/nginx/sites-enabled/vanyatra
        
        # Remove default site
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Test nginx config
        sudo nginx -t
        
        # Reload nginx
        sudo systemctl reload nginx
        sudo systemctl enable nginx
        
        rm /tmp/vanyatra-nginx.conf
EOF
    
    log_success "Nginx configured successfully"
}

# Main deployment logic
case "${1:-all}" in
    admin)
        build_admin
        deploy_admin
        log_success "Admin web deployment complete!"
        log_info "Access at: http://$SERVER_HOST or http://admin.vanyatra.com"
        ;;
    passenger)
        build_passenger
        deploy_passenger
        log_success "Passenger web deployment complete!"
        log_info "Access at: http://$SERVER_HOST or http://passenger.vanyatra.com"
        ;;
    all)
        log_info "Starting full deployment..."
        build_admin
        build_passenger
        setup_nginx
        deploy_admin
        deploy_passenger
        
        log_success "🎉 All deployments complete!"
        echo ""
        log_info "Admin Dashboard: http://$SERVER_HOST or http://admin.vanyatra.com"
        log_info "Passenger App: http://$SERVER_HOST or http://passenger.vanyatra.com"
        log_info "API: http://$SERVER_HOST:8000/api/"
        ;;
    *)
        log_error "Invalid argument. Use: admin, passenger, or all"
        exit 1
        ;;
esac
