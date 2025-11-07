#!/bin/bash

# DOGO2 Blazor Application - Linux Deployment Script
# Run this script with sudo privileges
# Usage: sudo ./deploy-linux.sh

set -e

# Configuration
APP_NAME="dogo2"
APP_DIR="/var/www/$APP_NAME"
PUBLISH_DIR="./DOGO2/bin/Release/net9.0/publish"
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$APP_NAME"
NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$APP_NAME"
ENV_FILE="/etc/$APP_NAME/env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo -e "DOGO2 Deployment Script for Linux"
echo -e "========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Step 1: Install dependencies
echo -e "${GREEN}[1/9] Installing dependencies...${NC}"
apt-get update
apt-get install -y nginx dotnet-sdk-9.0

# Verify dotnet installation
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    echo -e "  ${NC}.NET SDK version: $DOTNET_VERSION${NC}"
else
    echo -e "${RED}  ERROR: .NET SDK not found!${NC}"
    echo -e "${YELLOW}  Please install .NET 9.0 SDK manually${NC}"
    exit 1
fi

# Step 2: Create application directory
echo -e "${GREEN}[2/9] Setting up application directory...${NC}"
mkdir -p "$APP_DIR"
echo -e "  ${NC}Created directory: $APP_DIR${NC}"

# Step 3: Publish application
echo -e "${GREEN}[3/9] Publishing application...${NC}"
cd "$(dirname "$0")"
dotnet publish ./DOGO2/DOGO2.csproj -c Release -o "$PUBLISH_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}  ERROR: Failed to publish application${NC}"
    exit 1
fi
echo -e "  ${NC}Application published successfully${NC}"

# Step 4: Copy published files
echo -e "${GREEN}[4/9] Copying files to $APP_DIR...${NC}"
cp -r "$PUBLISH_DIR"/* "$APP_DIR/"
echo -e "  ${NC}Files copied successfully${NC}"

# Step 5: Set permissions
echo -e "${GREEN}[5/9] Setting permissions...${NC}"
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
echo -e "  ${NC}Permissions set for www-data${NC}"

# Step 6: Create environment file directory
echo -e "${GREEN}[6/9] Setting up environment configuration...${NC}"
mkdir -p "/etc/$APP_NAME"
if [ ! -f "$ENV_FILE" ]; then
    echo "# DOGO2 Environment Variables" > "$ENV_FILE"
    echo "# REQUIRED: Set your SQL Server password" >> "$ENV_FILE"
    echo "# SQL_PASSWORD=YOUR_SECURE_PASSWORD_HERE" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo -e "  ${YELLOW}Created $ENV_FILE - IMPORTANT: Edit this file and set SQL_PASSWORD${NC}"
else
    echo -e "  ${NC}Environment file already exists${NC}"
fi

# Step 7: Create systemd service
echo -e "${GREEN}[7/9] Creating systemd service...${NC}"
cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=DOGO2 Blazor Server Application
After=network.target

[Service]
WorkingDirectory=/var/www/dogo2
ExecStart=/usr/bin/dotnet /var/www/dogo2/DOGO2.dll

Restart=always
RestartSec=10
KillSignal=SIGINT

User=www-data
Group=www-data

Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ASPNETCORE_URLS=http://localhost:5000

EnvironmentFile=-/etc/dogo2/env

SyslogIdentifier=dogo2
StandardOutput=journal
StandardError=journal

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/www/dogo2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$APP_NAME"
echo -e "  ${NC}Systemd service created and enabled${NC}"

# Step 8: Configure Nginx
echo -e "${GREEN}[8/9] Configuring Nginx...${NC}"

# Check if nginx config example exists
if [ -f "./nginx-config.example.conf" ]; then
    cp ./nginx-config.example.conf "$NGINX_SITE_AVAILABLE"
    echo -e "  ${NC}Copied Nginx configuration from example${NC}"
else
    # Create basic nginx configuration
    cat > "$NGINX_SITE_AVAILABLE" << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts for Blazor Server
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
EOF
    echo -e "  ${NC}Created basic Nginx configuration${NC}"
fi

# Enable site
ln -sf "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo -e "  ${NC}Nginx configured and restarted${NC}"
else
    echo -e "${RED}  ERROR: Nginx configuration test failed${NC}"
    exit 1
fi

# Step 9: Start the application
echo -e "${GREEN}[9/9] Starting application...${NC}"
systemctl start "$APP_NAME"

# Wait a moment for the service to start
sleep 2

# Check service status
if systemctl is-active --quiet "$APP_NAME"; then
    echo -e "  ${GREEN}Application started successfully${NC}"
else
    echo -e "${RED}  ERROR: Application failed to start${NC}"
    echo -e "${YELLOW}  Check logs with: journalctl -u $APP_NAME -n 50${NC}"
fi

echo ""
echo -e "${CYAN}========================================"
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "${NC}1. Edit $ENV_FILE and add SQL_PASSWORD${NC}"
echo -e "${NC}2. Update appsettings.Production.json with your connection string${NC}"
echo -e "${NC}3. Update Nginx configuration with your domain: $NGINX_SITE_AVAILABLE${NC}"
echo -e "${NC}4. Configure SSL certificate (recommended - use certbot)${NC}"
echo -e "${NC}5. Restart services:${NC}"
echo -e "   ${NC}sudo systemctl restart $APP_NAME${NC}"
echo -e "   ${NC}sudo systemctl restart nginx${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo -e "  ${NC}View logs:        journalctl -u $APP_NAME -f${NC}"
echo -e "  ${NC}Restart app:      sudo systemctl restart $APP_NAME${NC}"
echo -e "  ${NC}Stop app:         sudo systemctl stop $APP_NAME${NC}"
echo -e "  ${NC}Service status:   sudo systemctl status $APP_NAME${NC}"
echo -e "  ${NC}Test Nginx:       sudo nginx -t${NC}"
echo -e "  ${NC}Reload Nginx:     sudo systemctl reload nginx${NC}"
echo ""
echo -e "${CYAN}Testing:${NC}"
echo -e "  ${NC}Local test:       curl http://localhost:5000${NC}"
echo -e "  ${NC}Via Nginx:        curl http://localhost${NC}"
echo ""

# Offer to show logs
read -p "Show application logs? (y/n): " SHOW_LOGS
if [ "$SHOW_LOGS" = "y" ]; then
    journalctl -u "$APP_NAME" -n 50 --no-pager
fi
