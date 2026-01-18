# CF Networking Demo - Presentation Notes

## Opening Statement
"I've built a demo showing how Cloud Foundry handles app networking through both Application Security Groups (ASGs) and Container-to-Container (C2C) Networking. Let me show you both concepts."

---

## Part 1: Container-to-Container Networking (5 minutes)

### What It Is
"C2C networking allows apps to talk directly to each other using internal DNS, without going through the public internet."

### The Demo
1. **Show the architecture:**
   ```
   Frontend (public) → Backend (internal only)
   ```

2. **Show it works:**
   - Open: `https://frontend-app.YOUR-DOMAIN`
   - Click "Call Backend App"
   - ✅ "See, it successfully calls the backend using an internal route"

3. **Show the internal route:**
   ```bash
   cf routes | grep backend-app
   ```
   "Notice backend-app.apps.internal - this is NOT accessible from the internet"

4. **Show the network policy:**
   ```bash
   cf network-policies
   ```
   "This policy explicitly allows frontend to talk to backend on TCP port 8080"

5. **Break it to prove it works:**
   ```bash
   cf remove-network-policy frontend-app backend-app --protocol tcp --port 8080
   ```
   - Refresh frontend, click "Call Backend App"
   - ❌ "Now it fails - without the policy, communication is blocked"

6. **Fix it:**
   ```bash
   cf add-network-policy frontend-app backend-app --protocol tcp --port 8080
   ```
   - Refresh and test again
   - ✅ "Works again"

### Key Points
- Backend is NOT on public internet (secure)
- Direct container networking (fast)
- Explicit policies required (zero-trust)
- Perfect for microservices

---

## Part 2: Application Security Groups (5 minutes)

### What It Is
"ASGs control outbound traffic from apps - what external services they can reach."

### The Demo
1. **Show the architecture:**
   ```
   External Client → httpbin.org (internet)
   ```

2. **Show it works (permissive ASG):**
   - Open: `https://external-client.YOUR-DOMAIN`
   - Click "Test External API Call"
   - ✅ "It works - the app can reach the internet"

3. **Show the current ASG:**
   ```bash
   cf security-groups
   cf space demo-space
   ```
   "allow-external-asg is bound to this space - it allows HTTPS traffic"

4. **Switch to restrictive ASG:**
   ```bash
   cf unbind-security-group allow-external-asg demo-org --space demo-space
   cf bind-security-group block-external-asg demo-org --space demo-space
   cf restart external-client
   ```
   - Wait for restart
   - Click "Test External API Call" again
   - ❌ "Now it fails - ASG blocks internet access"

5. **Show DNS still works:**
   - Click "Test DNS Resolution"
   - ✅ "DNS works because we have a separate DNS ASG"

6. **Show the ASG rules:**
   ```bash
   cat asgs/allow-external-asg.json
   cat asgs/block-external-asg.json
   cat asgs/dns-asg.json
   ```
   "ASGs are just JSON files defining protocol, destination IPs, and ports"

### Key Points
- ASGs control egress (outbound) traffic
- Can be platform-wide or space-specific
- Critical for security compliance
- Prevent unauthorized external API usage

---

## Part 3: Why Both Matter (2 minutes)

### Side-by-Side Comparison
"These solve different problems:"

| Feature | C2C Networking | ASGs |
|---------|----------------|------|
| **Controls** | App-to-app within CF | App-to-internet |
| **Direction** | Internal traffic | Outbound traffic |
| **Use Case** | Microservices | External APIs |
| **Security** | Zero-trust between apps | Prevent data exfil |

### Real-World Example
"Imagine a payment processing app:
- Frontend → Backend: C2C networking (internal, fast, secure)
- Backend → Stripe API: ASG allows only stripe.com (controlled egress)
- Backend → Random sites: Blocked by ASG (security)"

---

## Part 4: Advanced Topics (if time allows)

### Dynamic ASGs
"With Dynamic ASGs, changes take effect immediately - no app restart needed"
```bash
# Show in deployment manifest or mention
```

### Platform-wide vs Space-scoped
```bash
# Platform-wide
cf bind-running-security-group dns-asg

# Space-scoped
cf bind-security-group allow-external-asg demo-org --space demo-space
```

### Staging vs Running ASGs
"Apps might need different access during build vs runtime"
```bash
cf staging-security-groups  # More permissive
cf running-security-groups  # More restrictive
```

---

## Closing

"This demonstrates:
1. ✅ How to secure internal app communication with C2C
2. ✅ How to control external access with ASGs
3. ✅ That I understand CF networking concepts
4. ✅ How to implement defense-in-depth networking

Both are essential for production Cloud Foundry deployments."

---

## Common Questions

**Q: Why not just use public routes for everything?**
A: "Security, performance, and network segmentation. Internal routes never touch the internet."

**Q: What if I need to allow traffic to many external services?**
A: "Create ASGs with specific IP ranges and ports. You can have multiple ASGs per space."

**Q: Do apps always need network policies?**
A: "Only if they talk to each other. Apps can still reach the internet via ASGs without C2C policies."

**Q: What about performance impact?**
A: "C2C is actually faster than going through external routers. ASGs are just iptables rules - minimal overhead."

---

## Commands Cheat Sheet

```bash
# C2C Networking
cf add-network-policy SOURCE DEST --protocol tcp --port PORT
cf network-policies
cf remove-network-policy SOURCE DEST --protocol tcp --port PORT

# ASGs
cf create-security-group NAME FILE.json
cf bind-security-group NAME ORG --space SPACE
cf security-groups
cf unbind-security-group NAME ORG --space SPACE

# Useful
cf routes                    # Show all routes
cf apps                      # Show all apps
cf logs APP --recent        # Check logs
```