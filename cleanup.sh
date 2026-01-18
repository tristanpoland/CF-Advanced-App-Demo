#!/bin/bash

# CF Networking Demo - Cleanup Script

set -e

echo "======================================"
echo "CF Networking Demo - Cleanup"
echo "======================================"
echo ""

ORG_NAME="demo-org"
SPACE_NAME="demo-space"

echo "This will delete all demo resources:"
echo "  - Apps: frontend-app, backend-app, external-client"
echo "  - Network policies"
echo "  - Security groups (demo-specific)"
echo ""

read -p "Continue with cleanup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

cf target -o $ORG_NAME -s $SPACE_NAME

echo ""
echo "Removing network policies..."
cf remove-network-policy frontend-app backend-app --protocol tcp --port 8080 || true

echo ""
echo "Unbinding security groups..."
cf unbind-security-group allow-external-asg $ORG_NAME --space $SPACE_NAME || true
cf unbind-security-group block-external-asg $ORG_NAME --space $SPACE_NAME || true
cf unbind-running-security-group dns-asg || true
cf unbind-staging-security-group dns-asg || true

echo ""
echo "Deleting apps..."
cf delete frontend-app -f -r || true
cf delete backend-app -f -r || true
cf delete external-client -f -r || true

echo ""
echo "Deleting security groups..."
cf delete-security-group dns-asg -f || true
cf delete-security-group allow-external-asg -f || true
cf delete-security-group block-external-asg -f || true

echo ""
echo "======================================"
echo "Cleanup Complete!"
echo "======================================"
echo ""
echo "Note: Org and Space were preserved."
echo "To delete them manually:"
echo "  $ cf delete-space $SPACE_NAME -o $ORG_NAME -f"
echo "  $ cf delete-org $ORG_NAME -f"
echo ""