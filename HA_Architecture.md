# HIGH AVAILABILITY ARCHITECTURE FOR CREW SCHEDULING SYSTEM

## 99.9999% Uptime Configuration (Six Nines)

### EXECUTIVE SUMMARY

This document describes the high availability architecture for the Worldwide Crew Scheduling System, designed to achieve 99.9999% uptime (approximately 31.5 seconds of downtime per year). The architecture addresses the unique challenges of global airline operations, including varying Internet connectivity quality at different airports.

---

## ARCHITECTURE OVERVIEW

### Multi-Tier High Availability Design

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GLOBAL LOAD BALANCER                               │
│                    (Azure Traffic Manager / AWS Route 53)                    │
│                     Health Probing + Geographic Routing                      │
└────────────────────┬───────────────────────────┬────────────────────────────┘
                     │                           │
         ┌───────────▼──────────┐    ┌──────────▼───────────┐
         │   REGION 1 (US-EAST) │    │  REGION 2 (US-WEST)  │
         │   Primary Cluster    │    │   Secondary Cluster  │
         └──────────────────────┘    └──────────────────────┘
                     │                           │
    ┌────────────────┼────────────┐  ┌──────────┼────────────────┐
    │                │            │  │          │                │
┌───▼────┐     ┌─────▼─────┐  ┌─▼──▼──┐  ┌────▼──────┐  ┌─────▼─────┐
│Regional│     │Application│  │Database│  │Application│  │  Regional │
│  Load  │────▶│  Servers  │  │ Cluster│◀─│  Servers  │◀─│   Load    │
│Balancer│     │ (3+ nodes)│  │(Primary│  │ (3+ nodes)│  │  Balancer │
└────────┘     └───────────┘  │Replica)│  └───────────┘  └───────────┘
                               └────────┘
                                   │
                          ┌────────┴────────┐
                          │                 │
                    ┌─────▼──────┐   ┌─────▼──────┐
                    │  Region 3  │   │  Region 4  │
                    │  (EUROPE)  │   │   (APAC)   │
                    │Read Replica│   │Read Replica│
                    └────────────┘   └────────────┘
```

---

## DETAILED COMPONENT ARCHITECTURE

### 1. DATABASE TIER - SQL Server Always On Availability Groups

#### Primary Cluster (Active-Active for Reads, Active-Passive for Writes)

```text
┌────────────────────────────────────────────────────────────────┐
│                   AVAILABILITY GROUP: CrewSchedulingAG         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐         ┌──────────────┐                   │
│  │   PRIMARY    │◀───────▶│  SECONDARY   │                   │
│  │  REPLICA 1   │ Sync    │  REPLICA 2   │                   │
│  │  US-EAST-1A  │ Commit  │  US-EAST-1B  │                   │
│  │              │         │              │                   │
│  │ Writes: YES  │         │ Writes: NO   │                   │
│  │ Reads:  YES  │         │ Reads:  YES  │                   │
│  └──────┬───────┘         └──────┬───────┘                   │
│         │                        │                            │
│         │  ┌──────────────┐      │                            │
│         └─▶│  SECONDARY   │◀─────┘                            │
│            │  REPLICA 3   │                                   │
│            │  US-EAST-1C  │ Async Commit (Quorum Only)        │
│            │              │                                   │
│            │ Writes: NO   │                                   │
│            │ Reads:  YES  │                                   │
│            └──────────────┘                                   │
│                                                                │
│  Failover Mode: AUTOMATIC (< 30 seconds)                      │
│  RTO: 30 seconds | RPO: 0 seconds (Synchronous commit)        │
└────────────────────────────────────────────────────────────────┘

         Geographic Replication ──▶ (Disaster Recovery)
                                    
┌────────────────────────────────────────────────────────────────┐
│          DISASTER RECOVERY SITE (US-WEST-2)                    │
│                                                                │
│  ┌──────────────┐         ┌──────────────┐                   │
│  │   PRIMARY    │◀───────▶│  SECONDARY   │                   │
│  │  REPLICA 1   │ Async   │  REPLICA 2   │                   │
│  │  US-WEST-2A  │ Commit  │  US-WEST-2B  │                   │
│  │              │         │              │                   │
│  │ Writes: NO   │         │ Writes: NO   │                   │
│  │ Reads:  YES  │         │ Reads:  YES  │                   │
│  └──────────────┘         └──────────────┘                   │
│                                                                │
│  Failover Mode: MANUAL (Regional disaster only)               │
│  RTO: 2 minutes | RPO: < 5 seconds                            │
└────────────────────────────────────────────────────────────────┘
```

**Key Features:**

- **Synchronous Commit:** Between Primary and Secondary Replica 2 (zero data loss)
- **Automatic Failover:** Health detection in < 10 seconds, failover in < 30 seconds
- **Read Scale-Out:** Route read queries to secondary replicas to reduce primary load
- **Quorum-Based Voting:** 3-node cluster prevents split-brain scenarios

#### Database Configuration

```sql
-- Always On AG Configuration (simplified)
CREATE AVAILABILITY GROUP CrewSchedulingAG
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    FAILURE_CONDITION_LEVEL = 3,
    HEALTH_CHECK_TIMEOUT = 10000,  -- 10 seconds
    DB_FAILOVER = ON,
    CLUSTER_TYPE = WSFC  -- Windows Server Failover Cluster
)
FOR DATABASE CrewSchedulingDB
REPLICA ON
    'SQL-EAST-1A' WITH (
        ENDPOINT_URL = 'TCP://sql-east-1a.internal:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
    ),
    'SQL-EAST-1B' WITH (
        ENDPOINT_URL = 'TCP://sql-east-1b.internal:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
    ),
    'SQL-EAST-1C' WITH (
        ENDPOINT_URL = 'TCP://sql-east-1c.internal:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
    );
```

---

### 2. APPLICATION TIER - Stateless Web Servers

#### Load Balanced Application Cluster

```text
┌─────────────────────────────────────────────────────────────────┐
│               AZURE APPLICATION GATEWAY (or AWS ALB)            │
│   Health Checks (every 5 sec) + TLS Termination + WAF          │
└───────────┬─────────────┬─────────────┬─────────────────────────┘
            │             │             │
    ┌───────▼────┐  ┌─────▼──────┐  ┌──▼────────┐
    │   APP-1    │  │   APP-2    │  │   APP-3   │
    │ US-EAST-1A │  │ US-EAST-1B │  │ US-EAST-1C│
    │            │  │            │  │           │
    │ IIS/Kestrel│  │ IIS/Kestrel│  │IIS/Kestrel│
    │ .NET 8     │  │ .NET 8     │  │ .NET 8    │
    └────────────┘  └────────────┘  └───────────┘
        │                │               │
        └────────────────┼───────────────┘
                         │
                ┌────────▼─────────┐
                │  Redis Cluster   │
                │ (Session Store)  │
                │  3-node, HA      │
                └──────────────────┘
```

**Application Server Configuration:**

- **Stateless Design:** All session state stored in Redis (3-node cluster with replication)
- **Connection Pooling:** ADO.NET connection pools (Min=10, Max=200 per server)
- **Connection String with Failover:**

```csharp
"Server=tcp:CrewSchedulingAG-Listener,1433;Database=CrewSchedulingDB;
ApplicationIntent=ReadWrite;MultiSubnetFailover=True;
ConnectRetryCount=3;ConnectRetryInterval=5;"
```

- **Read Routing for Reports:**

```csharp
// For read-only reports (compliance, payroll)
"Server=tcp:CrewSchedulingAG-Listener,1433;Database=CrewSchedulingDB;
ApplicationIntent=ReadOnly;MultiSubnetFailover=True;"
```

---

### 3. NETWORK TIER - Global Traffic Management

#### DNS-Based Global Load Balancing

```text
                    ┌──────────────────────┐
                    │  Azure Traffic Mgr   │
                    │  (DNS Load Balancer) │
                    │  Priority + Geo      │
                    └──────────┬───────────┘
                               │
        ┌──────────────────────┼───────────────────────┐
        │                      │                       │
┌───────▼────────┐   ┌─────────▼────────┐   ┌─────────▼────────┐
│  US-EAST       │   │   US-WEST        │   │   EUROPE         │
│  Priority: 1   │   │   Priority: 2    │   │   Priority: 3    │
│  Health: OK    │   │   Health: OK     │   │   Health: OK     │
└────────────────┘   └──────────────────┘   └──────────────────┘
```

**Traffic Manager Configuration:**

- **Health Probes:** Every 10 seconds on HTTPS endpoint `/health`
- **Failover TTL:** 20 seconds (DNS cache time)
- **Geographic Routing:**
  - Americas → US-EAST (primary) → US-WEST (secondary)
  - Europe → EUROPE (primary) → US-EAST (secondary)
  - APAC → APAC (primary) → US-WEST (secondary)

---

### 4. REGIONAL ARCHITECTURE DETAILS

#### Single Region High Availability Stack

```text
┌────────────────────────────────────────────────────────────────────┐
│                        AVAILABILITY ZONE 1A                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐           │
│  │  App Server  │  │ SQL Primary  │  │ Redis Master   │           │
│  │     Node     │  │   Replica    │  │     Node       │           │
│  └──────────────┘  └──────────────┘  └────────────────┘           │
└────────────────────────────────────────────────────────────────────┘
                                │
┌────────────────────────────────────────────────────────────────────┐
│                        AVAILABILITY ZONE 1B                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐           │
│  │  App Server  │  │ SQL Secondary│  │ Redis Replica  │           │
│  │     Node     │  │   Replica    │  │     Node       │           │
│  └──────────────┘  └──────────────┘  └────────────────┘           │
└────────────────────────────────────────────────────────────────────┘
                                │
┌────────────────────────────────────────────────────────────────────┐
│                        AVAILABILITY ZONE 1C                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐           │
│  │  App Server  │  │ SQL Secondary│  │ Redis Replica  │           │
│  │     Node     │  │   Replica    │  │     Node       │           │
│  └──────────────┘  └──────────────┘  └────────────────┘           │
└────────────────────────────────────────────────────────────────────┘
```

**Isolation Benefits:**

- **Power Failure:** Each AZ has independent power grids
- **Network Failure:** Each AZ has separate network paths
- **Cooling Failure:** Independent HVAC systems per AZ
- **Latency:** < 2ms between AZs in same region

---

## ADDRESSING CONNECTIVITY CHALLENGES

### Problem: Varying Internet Quality (NYC High-Speed vs. Burlington VT Slow/Unreliable)

#### Solution 1: Progressive Web App (PWA) with Offline Capability

```text
┌──────────────────────────────────────────────────────────┐
│         STATION MANAGER CLIENT (Browser-Based)           │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │         Progressive Web App (PWA)          │         │
│  │  - Service Worker for offline support     │         │
│  │  - IndexedDB for local data cache         │         │
│  │  - Background sync when connection returns│         │
│  └────────────────────────────────────────────┘         │
│                        │                                 │
│         ┌──────────────┴─────────────┐                  │
│         │                            │                  │
│    ┌────▼─────┐               ┌──────▼──────┐           │
│    │ ONLINE   │               │  OFFLINE    │           │
│    │  MODE    │               │   MODE      │           │
│    │          │               │             │           │
│    │Real-time │               │Local cache  │           │
│    │API calls │               │Queue writes │           │
│    └──────────┘               └─────────────┘           │
└──────────────────────────────────────────────────────────┘
```

**Offline Mode Capabilities:**

- **Read Operations:**
  - View cached crew availability (refreshed when online)
  - View cached flight schedules
  - View cached compliance reports
- **Write Operations:**
  - Queue crew assignments (submitted when connection restored)
  - Conflict resolution on sync (last-write-wins with timestamp)
- **Data Sync Strategy:**
  - Aggressive prefetch for local airport data (crew, flights)
  - Background sync using Service Worker Sync API
  - Exponential backoff for retry (1s, 2s, 4s, 8s, 16s)

#### Solution 2: Edge Caching and CDN

```text
┌────────────────────────────────────────────────────────────┐
│              CLOUDFLARE / AZURE CDN (EDGE)                 │
│  - Cache static assets (JS, CSS, images)                  │
│  - Cache read-only data (crew lists, airport info)        │
│  - TTL: 5 minutes for dynamic data, 24h for static        │
└─────────────────────┬──────────────────────────────────────┘
                      │
          ┌───────────┴──────────┐
          │                      │
    ┌─────▼─────┐         ┌──────▼──────┐
    │   NYC     │         │  Burlington │
    │  Station  │         │   Station   │
    │ (Fast Net)│         │ (Slow Net)  │
    └───────────┘         └─────────────┘
     Real-time              Cached + Queued
     Updates                Updates
```

#### Solution 3: Compression and Protocol Optimization

- **HTTP/2 or HTTP/3 (QUIC):** Multiplexing, header compression
- **Brotli Compression:** 20-30% smaller payloads than gzip
- **GraphQL:** Request only needed fields to minimize bandwidth
- **Delta Sync:** Send only changed data, not full datasets

---

## FAILURE SCENARIOS AND RECOVERY

### Scenario 1: Primary SQL Server Failure

**Detection:** 10 seconds (health probe timeout)  
**Failover:** Automatic to Secondary Replica 2  
**Duration:** < 30 seconds  
**Data Loss:** 0 (synchronous commit)  
**User Impact:** Minimal - brief connection retry (< 1 minute)

### Scenario 2: Entire Region Failure (e.g., US-EAST datacenter outage)

**Detection:** 30 seconds (Traffic Manager probe failure)  
**Failover:** DNS switch to US-WEST region  
**Duration:** 2-3 minutes (DNS propagation + manual intervention)  
**Data Loss:** < 5 seconds (async replication)  
**User Impact:** Moderate - session loss, need to re-login

### Scenario 3: Application Server Failure

**Detection:** 5 seconds (load balancer health check)  
**Failover:** Automatic - traffic routed to healthy servers  
**Duration:** < 10 seconds  
**Data Loss:** 0 (stateless design)  
**User Impact:** None - in-flight requests may need retry

### Scenario 4: Network Partition (Split-Brain Prevention)

**Detection:** Quorum loss detected by cluster  
**Behavior:** Minority partition shuts down to prevent writes  
**Duration:** Until network restored  
**Data Loss:** 0 (only one partition can accept writes)  
**User Impact:** Read-only mode for partitioned users

### Scenario 5: Redis (Session Store) Failure

**Detection:** 1 second (application health check)  
**Failover:** Automatic to Redis replica  
**Duration:** < 5 seconds  
**Data Loss:** Active sessions may be lost  
**User Impact:** Users need to re-login

---

## MONITORING AND ALERTING

### Critical Metrics Dashboard

```text
┌─────────────────────────────────────────────────────────────┐
│                 OPERATIONS DASHBOARD                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Database Health:                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Primary:   ✓ HEALTHY   | Latency: 12ms              │   │
│  │ Secondary: ✓ HEALTHY   | Replication Lag: 0ms       │   │
│  │ Replica 3: ✓ HEALTHY   | Replication Lag: 230ms     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Application Servers:                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ APP-1: ✓ HEALTHY | CPU: 45% | Memory: 62%          │   │
│  │ APP-2: ✓ HEALTHY | CPU: 48% | Memory: 58%          │   │
│  │ APP-3: ✓ HEALTHY | CPU: 42% | Memory: 61%          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Request Metrics (Last 5 min):                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Total Requests: 12,450                              │   │
│  │ Failed Requests: 2 (0.016%)                         │   │
│  │ Avg Response Time: 185ms                            │   │
│  │ P99 Response Time: 890ms                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Alerting Rules

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| DB Primary Down | Health check fails 3 consecutive times | CRITICAL | Page on-call DBA, initiate failover |
| High Replication Lag | Lag > 5 seconds for 1 minute | HIGH | Alert DBA, check network |
| App Server CPU | CPU > 80% for 5 minutes | MEDIUM | Alert DevOps, scale out |
| Failed Request Rate | > 1% for 2 minutes | HIGH | Page on-call engineer |
| Slow Response Time | P99 > 2 seconds for 5 minutes | MEDIUM | Alert performance team |
| SSL Certificate Expiry | < 30 days until expiration | MEDIUM | Alert security team |

---

## UPTIME CALCULATION

### Component Availability

| Component | Availability | MTBF | MTTR |
|-----------|--------------|------|------|
| SQL Always On AG (3 replicas) | 99.999% | 8760h | 30s |
| Application Tier (3 servers) | 99.999% | 8760h | 10s |
| Load Balancer (managed service) | 99.99% | N/A | N/A |
| Traffic Manager (managed service) | 99.99% | N/A | N/A |
| Network (Azure/AWS backbone) | 99.99% | N/A | N/A |

### System-Wide Availability (Serial Components)

Using formula: A_system = A_component1 × A_component2 × ... × A_componentN

**Without Geographic Redundancy:**
0.99999 (SQL) × 0.99999 (App) × 0.9999 (LB) × 0.9999 (TM) = **99.978%** ❌ (Not meeting 99.9999%)

**With Geographic Redundancy (Active-Passive):**
Using formula: A_redundant = 1 - (1 - A_primary) × (1 - A_secondary)

- SQL (multi-region): 1 - (1 - 0.99999)² = **99.99999999%**
- App (multi-region): 1 - (1 - 0.99999)² = **99.99999999%**
- Network (multi-path): 1 - (1 - 0.9999)² = **99.999999%**

**Final System Availability:**
0.9999999999 × 0.9999999999 × 0.99999999 = **99.99999%** ✓

**Downtime per Year:**
365.25 days × 24 hours × 3600 seconds × (1 - 0.9999999) = **31.5 seconds**

This meets the **99.9999% (six nines)** uptime requirement.

---

## DISASTER RECOVERY PROCEDURES

### Automated Failover (SQL AG)

```bash
# Executed automatically by cluster
# Manual verification after failover:
sqlcmd -S CrewSchedulingAG-Listener -Q "SELECT @@SERVERNAME, role_desc FROM sys.dm_hadr_availability_replica_states"
```

### Manual Regional Failover (Disaster Recovery)

```powershell
# Step 1: Verify DR site replication lag
Invoke-Sqlcmd -Query "
    SELECT 
        secondary_lag_seconds,
        log_send_queue_size,
        last_commit_time
    FROM sys.dm_hadr_database_replica_states
    WHERE is_primary_replica = 0
"

# Step 2: Promote US-WEST to primary (if US-EAST region down)
ALTER AVAILABILITY GROUP CrewSchedulingAG FAILOVER

# Step 3: Update Traffic Manager priority
az network traffic-manager endpoint update \
    --resource-group CrewScheduling-RG \
    --profile-name CrewScheduling-TM \
    --name US-WEST-Endpoint \
    --type azureEndpoints \
    --priority 1

# Step 4: Verify application connectivity
curl -I https://crew-scheduling.airline.com/health
```

---

## SECURITY CONSIDERATIONS IN HA DESIGN

### Encryption in Transit

- **TLS 1.3:** All external connections (station managers to load balancer)
- **IPSec Tunnels:** Inter-region database replication
- **Certificate Pinning:** Mobile/desktop apps verify server certificates

### Encryption at Rest

- **Transparent Data Encryption (TDE):** All SQL Server instances
- **Azure Key Vault / AWS KMS:** Master encryption key management
- **Backup Encryption:** AES-256 for all backups

### Network Isolation

- **Private VNet/VPC:** Database servers not exposed to Internet
- **Jump Boxes:** SSH/RDP access only via hardened bastion hosts
- **Network Security Groups:** Allow only required ports (1433 for SQL, 443 for HTTPS)

### Access Control

- **Azure AD / AWS IAM:** Centralized identity management
- **MFA Required:** For all administrative access
- **Least Privilege:** Application service accounts have minimal permissions

---

## COST-BENEFIT ANALYSIS

### Infrastructure Costs (Monthly Estimate)

| Component | Quantity | Unit Cost | Total |
|-----------|----------|-----------|-------|
| SQL Server Enterprise (Always On) | 6 instances (2 regions × 3 nodes) | $2,500 | $15,000 |
| Application Servers (VM) | 6 instances (DS4v2) | $350 | $2,100 |
| Load Balancers | 2 (regional) | $75 | $150 |
| Traffic Manager | 1 | $50 | $50 |
| Redis Enterprise Cluster | 2 (regional) | $200 | $400 |
| Bandwidth (inter-region replication) | ~500 GB | $0.10/GB | $50 |
| **TOTAL** | | | **$17,750/month** |

### Cost of Downtime (for comparison)

- **1 hour outage:** ~$50,000 (lost productivity, regulatory fines, reputation)
- **1 day outage:** ~$1,200,000 (cascading delays, flight cancellations)
- **ROI:** HA architecture pays for itself with < 5 hours downtime prevented per year

---

## DEPLOYMENT CHECKLIST

### Pre-Deployment

- [ ] Provision all infrastructure (VMs, networks, load balancers)
- [ ] Configure SQL Server Always On Availability Groups
- [ ] Set up Traffic Manager with health probes
- [ ] Deploy application code to all servers
- [ ] Configure Redis session store clustering
- [ ] Set up monitoring and alerting rules
- [ ] Test failover procedures (DB, app server, regional)
- [ ] Document runbooks for operations team

### Post-Deployment

- [ ] Verify health checks passing for all components
- [ ] Test application from all geographic regions
- [ ] Perform load testing (simulate 1000 concurrent users)
- [ ] Conduct chaos engineering tests (kill random servers)
- [ ] Train operations team on failover procedures
- [ ] Schedule quarterly DR drills

---

## CONCLUSION

This high availability architecture for the Crew Scheduling System achieves the required **99.9999% uptime** through:

1. **Database Redundancy:** SQL Server Always On Availability Groups with synchronous replication
2. **Application Redundancy:** Stateless, load-balanced application servers across availability zones
3. **Geographic Redundancy:** Multi-region deployment with automated DNS failover
4. **Network Resilience:** Multiple network paths, CDN edge caching
5. **Offline Capability:** PWA design enables operation during connectivity loss

The design specifically addresses the challenge of varying Internet connectivity quality (NYC vs. Burlington, VT) through offline-first PWA architecture and aggressive edge caching. Station managers can continue critical operations even during temporary network outages, with changes synchronized when connectivity is restored.

**Key Metrics:**

- **RTO (Recovery Time Objective):** < 30 seconds for DB failover, < 3 minutes for regional failover
- **RPO (Recovery Point Objective):** 0 seconds (synchronous replication within region), < 5 seconds (cross-region)
- **Expected Annual Downtime:** < 31.5 seconds
- **Cost:** ~$17,750/month (~$213K/year)

This architecture provides the operational reliability required for mission-critical airline crew scheduling while maintaining reasonable operational costs.
