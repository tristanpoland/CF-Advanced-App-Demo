#!/bin/bash

# CF Networking Demo - Deployment Script
# This script demonstrates both ASGs and Container-to-Container Networking

set -e

echo "======================================"
echo "CF Networking Demo - Deployment Script"
echo "======================================"
echo ""

# Configuration - EDIT THESE VALUES
ORG_NAME="demo-org"
SPACE_NAME="demo-space"
DOMAIN="apps.example.com"  # Replace with your CF domain

echo "Checking prerequisites..."
if ! command -v cf &> /dev/null; then
    echo "ERROR: CF CLI is not installed"
    exit 1
fi

echo "Current CF target:"
cf target

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Create org and space (if needed)
echo ""
echo "Step 1: Setting up Org and Space"
echo "--------------------------------"
cf create-org $ORG_NAME || true
cf create-space $SPACE_NAME -o $ORG_NAME || true
cf target -o $ORG_NAME -s $SPACE_NAME

# Step 2: Deploy all apps
echo ""
echo "Step 2: Deploying Applications"
echo "-------------------------------"

echo "Deploying frontend-app..."
cd frontend-app
cf push frontend-app --no-start
cf set-env frontend-app BACKEND_URL "http://backend-app.apps.internal:8080"
cd ..

echo "Deploying backend-app..."
cd backend-app
cf push backend-app --no-start
cd ..

echo "Deploying external-client..."
cd external-client
cf push external-client --no-start
cd ..

# Step 3: Map internal route for backend
echo ""
echo "Step 3: Configuring Internal Route"
echo "-----------------------------------"
cf map-route backend-app apps.internal --hostname backend-app

# Step 4: Create and bind ASGs
echo ""
echo "Step 4: Configuring Application Security Groups"
echo "------------------------------------------------"

# Create DNS ASG (required for all apps)
echo "Creating DNS ASG..."
cf create-security-group dns-asg asgs/dns-asg.json || true
cf bind-running-security-group dns-asg
cf bind-staging-security-group dns-asg

# Create permissive ASG for external access
echo "Creating permissive external ASG..."
cf create-security-group allow-external-asg asgs/allow-external-asg.json || true

# Create restrictive ASG
echo "Creating restrictive ASG..."
cf create-security-group block-external-asg asgs/block-external-asg.json || true

# Bind permissive ASG to external-client
echo "Binding permissive ASG to external-client..."
cf bind-security-group allow-external-asg $ORG_NAME --space $SPACE_NAME

echo ""
echo "ASG Status:"
cf security-groups

# Step 5: Start apps
echo ""
echo "Step 5: Starting Applications"
echo "------------------------------"
cf start frontend-app
cf start backend-app
cf start external-client

# Step 6: Create container-to-container network policy
echo ""
echo "Step 6: Creating Container-to-Container Network Policy"
echo "-------------------------------------------------------"
echo "Creating policy: frontend-app -> backend-app (TCP port 8080)"
cf add-network-policy frontend-app backend-app --protocol tcp --port 8080

echo ""
echo "Network Policies:"
cf network-policies

# Step 7: Display summary
echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "App URLs:"
echo "  Frontend:        https://frontend-app.$DOMAIN"
echo "  External Client: https://external-client.$DOMAIN"
echo "  Backend:         http://backend-app.apps.internal:8080 (internal only)"
echo ""
echo "What to demonstrate:"
echo ""
echo "1. CONTAINER-TO-CONTAINER NETWORKING:"
echo "   - Visit frontend-app and click 'Call Backend App'"
echo "   - It successfully calls backend via internal route"
echo "   - Backend is NOT accessible from public internet"
echo ""
echo "2. APPLICATION SECURITY GROUPS:"
echo "   - Visit external-client and test external API"
echo "   - It succeeds because allow-external-asg is bound"
echo "   - To block external access:"
echo "     $ cf unbind-security-group allow-external-asg $ORG_NAME --space $SPACE_NAME"
echo "     $ cf bind-security-group block-external-asg $ORG_NAME --space $SPACE_NAME"
echo "     $ cf restart external-client"
echo ""
echo "3. VIEW CONFIGURATIONS:"
echo "   $ cf network-policies              # Show C2C policies"
echo "   $ cf security-groups               # Show all ASGs"
echo "   $ cf running-security-groups       # Show running ASGs"
echo ""
echo "4. CLEANUP (when done):"
echo "   $ ./cleanup.sh"
echo ""