# Cloud Foundry Networking Demo

This demo shows how **Application Security Groups (ASGs)** and **Container-to-Container (C2C) Networking** work in Cloud Foundry.

## Architecture

```
┌─────────────────┐
│  Frontend App   │ ──> Public route (frontend-app.apps.example.com)
│  (Node.js)      │ ──> Calls backend via C2C networking
└────────┬────────┘
         │
         │ C2C Network Policy
         │ (TCP port 8080)
         ↓
┌─────────────────┐
│  Backend App    │ ──> Internal route ONLY (backend-app.apps.internal)
│  (Node.js)      │ ──> Not accessible from internet
└─────────────────┘

┌─────────────────┐
│ External Client │ ──> Public route (external-client.apps.example.com)
│  (Node.js)      │ ──> Calls external APIs (controlled by ASG)
└─────────────────┘
```

## What This Demonstrates

### 1. Container-to-Container (C2C) Networking
- **Frontend → Backend communication** via internal DNS
- Backend uses `.apps.internal` domain (not publicly accessible)
- Network policy explicitly allows frontend → backend traffic
- Without the policy, communication fails

### 2. Application Security Groups (ASGs)
- **Control egress traffic** (outbound from apps)
- DNS ASG allows DNS resolution (required)
- Permissive ASG allows external HTTPS calls
- Restrictive ASG blocks internet access
- Can be applied per space or platform-wide

## Prerequisites

- Cloud Foundry installation with:
  - Container-to-container networking enabled
  - Service discovery enabled
- CF CLI v8 or later
- Network admin or space developer permissions

## Quick Start

### 1. Edit Configuration

Edit `deploy.sh` and update these values:
```bash
DOMAIN="apps.example.com"  # Your CF apps domain
```

### 2. Deploy Everything

```bash
cd cf-networking-demo
./deploy.sh
```

This will:
- Create demo-org and demo-space
- Deploy 3 apps (frontend, backend, external-client)
- Create and bind ASGs
- Create C2C network policy
- Map internal route for backend

### 3. Test the Demo

#### Test C2C Networking
1. Visit: `https://frontend-app.YOUR-DOMAIN`
2. Click "Call Backend App"
3. ✅ Should succeed - shows C2C networking works
4. Try accessing `http://backend-app.apps.internal` directly
5. ❌ Should fail - backend is internal only

#### Test ASGs
1. Visit: `https://external-client.YOUR-DOMAIN`
2. Click "Test External API Call"
3. ✅ Should succeed - ASG allows external traffic

Now block external traffic:
```bash
cf target -o demo-org -s demo-space
cf unbind-security-group allow-external-asg demo-org --space demo-space
cf bind-security-group block-external-asg demo-org --space demo-space
cf restart external-client
```

4. Click "Test External API Call" again
5. ❌ Should fail - ASG now blocks external traffic

### 4. Show Your Boss

**Demonstrate C2C Networking:**
```bash
# View network policies
cf network-policies

# Remove policy to show it breaks
cf remove-network-policy frontend-app backend-app --protocol tcp --port 8080

# Frontend can no longer reach backend
# Visit frontend-app and try calling backend - it will fail

# Re-add policy to fix
cf add-network-policy frontend-app backend-app --protocol tcp --port 8080
```

**Demonstrate ASGs:**
```bash
# View all security groups
cf security-groups

# View space-specific groups
cf space demo-space

# Toggle between permissive/restrictive
cf bind-security-group allow-external-asg demo-org --space demo-space
cf restart external-client
# External calls work

cf unbind-security-group allow-external-asg demo-org --space demo-space
cf bind-security-group block-external-asg demo-org --space demo-space
cf restart external-client
# External calls fail
```

## Understanding the Components

### Frontend App
- **Route:** Public (frontend-app.YOUR-DOMAIN)
- **Function:** Web UI that calls backend
- **Networking:** Uses `http://backend-app.apps.internal:8080`

### Backend App
- **Route:** Internal ONLY (backend-app.apps.internal)
- **Function:** API that returns data
- **Networking:** Only accessible via C2C policies

### External Client App
- **Route:** Public (external-client.YOUR-DOMAIN)
- **Function:** Tests external API calls
- **Networking:** Demonstrates ASG restrictions

### ASG Files

**dns-asg.json** - DNS resolution (required)
```json
[
  {
    "protocol": "tcp",
    "destination": "0.0.0.0/0",
    "ports": "53"
  },
  {
    "protocol": "udp",
    "destination": "0.0.0.0/0",
    "ports": "53"
  }
]
```

**allow-external-asg.json** - Allows HTTP/HTTPS
```json
[
  {
    "protocol": "tcp",
    "destination": "0.0.0.0/0",
    "ports": "443"
  }
]
```

**block-external-asg.json** - Only private networks
```json
[
  {
    "protocol": "tcp",
    "destination": "10.0.0.0/8",
    "ports": "1-65535"
  }
]
```

## Key CF Commands Used

### C2C Networking
```bash
# Map internal route
cf map-route backend-app apps.internal --hostname backend-app

# Add network policy
cf add-network-policy SOURCE DEST --protocol tcp --port 8080

# View policies
cf network-policies

# Remove policy
cf remove-network-policy SOURCE DEST --protocol tcp --port 8080
```

### Application Security Groups
```bash
# Create ASG
cf create-security-group NAME rules.json

# Bind to space (running)
cf bind-security-group NAME ORG --space SPACE

# Bind platform-wide (running)
cf bind-running-security-group NAME

# Bind platform-wide (staging)
cf bind-staging-security-group NAME

# View all ASGs
cf security-groups

# View running ASGs
cf running-security-groups

# Unbind ASG
cf unbind-security-group NAME ORG --space SPACE

# Delete ASG (must unbind first)
cf delete-security-group NAME
```

## Cleanup

```bash
./cleanup.sh
```

This removes:
- All apps
- Network policies
- Security groups (demo-specific)
- Preserves org and space

## Troubleshooting

### Frontend can't reach backend
```bash
# Check network policy exists
cf network-policies

# Check backend route is mapped
cf routes

# Check apps are running
cf apps
```

### External calls fail unexpectedly
```bash
# Check which ASGs are bound
cf security-groups

# Check space-specific ASGs
cf space demo-space

# Verify DNS ASG is bound
cf running-security-groups | grep dns-asg
```

### Apps won't start
```bash
# Check logs
cf logs APP-NAME --recent

# Check staging ASGs
cf staging-security-groups

# Ensure DNS ASG is bound for staging
cf bind-staging-security-group dns-asg
```

## Key Concepts Explained

### Why C2C Networking?
- **Security:** Backend not exposed to internet
- **Performance:** Direct container networking (no external routing)
- **Flexibility:** Fine-grained network policies per app

### Why ASGs?
- **Egress control:** Prevent apps from calling unauthorized services
- **Compliance:** Meet security requirements
- **Cost control:** Prevent unexpected external API usage

### ASG vs C2C
- **ASGs:** Control outbound traffic to IPs/ports outside CF
- **C2C:** Control traffic between CF apps
- Both are needed for complete network security!

## References

- [Cloud Foundry ASG Documentation](https://docs.cloudfoundry.org/concepts/asg.html)
- [Cloud Foundry C2C Networking Documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/cf-networking.html)
- [CF Networking Release](https://github.com/cloudfoundry/cf-networking-release)

## License

This demo is for educational purposes. Use freely.