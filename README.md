# Crew Scheduling System - Complete Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Requirements from Task](#requirements-from-task)
3. [Database Architecture](#database-architecture)
4. [Data Structures](#data-structures)
5. [Business Logic](#business-logic)
6. [Regulatory Compliance](#regulatory-compliance)
7. [Security Implementation](#security-implementation)
8. [High Availability Architecture](#high-availability-architecture)
9. [Installation and Setup](#installation-and-setup)
10. [Usage Guide](#usage-guide)
11. [Testing](#testing)

---

## Project Overview

The Crew Scheduling System is a comprehensive database solution for managing airline crew assignments for commercial flights. The system ensures regulatory compliance with FAA regulations (14 CFR Part 117 and 121.467) while optimizing crew scheduling and workload distribution.

### Key Features

- **Regulatory Compliance**: Automatic validation against FAA flight time limitations for pilots and flight attendants
- **Dynamic Hour Tracking**: Real-time calculation of crew hours from actual flight history
- **Crew Scheduling**: Intelligent assignment of crew to flights based on availability, location, and regulatory limits
- **Reporting**: Comprehensive reports for operations, compliance, and HR/payroll
- **Security**: Encrypted storage of sensitive data (SSN) using SQL Server encryption
- **High Availability**: Architecture designed for 99.9999% uptime

---

## Requirements from Task

### Crew Requirements (Per Flight)
- **Pilots**: 2 pilots minimum, with at least 1 senior (captain)
- **Cabin Crew**: 3 flight attendants minimum, with at least 1 senior

### Metadata Tracked

**For Each Crew Member:**
- Full name (first and last)
- Social Security Number (encrypted)
- Number of hours flown in the last 168 hours (7 days)
- Number of hours flown in the last 672 hours (28 days)
- Number of hours flown in the last 365 days
- Crew type (1 = flight attendant / 2 = pilot)
- Crew seniority (1 = trainee / 2 = journeyman / 3 = senior)
- Base airport location

**For Each Flight:**
- Airline
- Flight number
- Departure city/airport
- Destination city/airport
- Flight duration (minutes)
- Scheduled and actual departure times
- Actual arrival time
- International vs domestic flag
- Current status (Scheduled/InFlight/Landed)

### Required Reports
1. **Crew on planes currently in flight**
2. **Crew exceeding or at risk of exceeding work hour limitations**
3. **Hours worked per month per employee** (for payroll)
4. **Available crew for scheduling** (query functionality)

---

## Database Architecture

### Database Configuration
- **Name**: CrewSchedulingDB
- **Collation**: SQL_Latin1_General_CP1_CI_AS
- **Recovery Model**: FULL
- **Compatibility Level**: 150 (SQL Server 2019)

### Entity Relationship Overview

```
Airlines (1) ----< (M) Flights
Airports (1) ----< (M) Flights (Departure)
Airports (1) ----< (M) Flights (Destination)
Airports (1) ----< (M) Crew (Base)
Crew (1) ----< (M) CrewAssignments
Flights (1) ----< (M) CrewAssignments
```

### Table Structure

#### Core Tables

**1. Airlines**
- Stores airline company information
- Fields: AirlineID (PK), AirlineName, IATACode (unique)

**2. Airports**
- Stores airport/city information
- Fields: AirportID (PK), City, Country, IATACode (unique)

**3. Crew**
- Stores crew member information
- Fields: CrewID (PK), FirstName, LastName, SSN (encrypted), BaseAirportID (FK), CrewTypeID (FK), SeniorityID (FK), IsActive
- **Note**: Hour tracking removed in favor of dynamic calculation

**4. Flights**
- Stores flight information
- Fields: FlightID (PK), AirlineID (FK), FlightNumber, DepartureAirportID (FK), DestinationAirportID (FK), FlightDuration, ScheduledDeparture, ActualDeparture, ActualArrival, IsInternational, StatusID (FK)

**5. CrewAssignments**
- Junction table linking crew to flights
- Fields: AssignmentID (PK), FlightID (FK), CrewID (FK), RoleID (FK), AssignedAt

#### Lookup Tables

**6. CrewTypes**: Defines crew types (1=Flight Attendant, 2=Pilot)

**7. SeniorityLevels**: Defines seniority (1=Trainee, 2=Journeyman, 3=Senior)

**8. FlightStatuses**: Defines flight status (1=Scheduled, 2=InFlight, 3=Landed)

**9. Roles**: Defines crew role on flight (1=Pilot, 2=Cabin)

### Indexes

Performance-optimized indexes on:
- Crew.BaseAirportID
- Crew.CrewTypeID
- Flights.DepartureAirportID
- Flights.StatusID
- Flights.ScheduledDeparture
- CrewAssignments.FlightID
- CrewAssignments.CrewID
- CrewAssignments.RoleID
- CrewAssignments.AssignedAt

---

## Data Structures

### Key Design Decisions

#### 1. Dynamic Hour Calculation
Instead of storing static hour counts that require trigger maintenance, the system dynamically calculates hours from flight history using the `fn_CalculateCrewHours` function. This ensures:
- Always accurate hour calculations
- Proper time window handling (168h, 672h, 365 days)
- No data inconsistency issues

#### 2. International Flight Flag
The `IsInternational` flag on Flights enables proper enforcement of FA duty time limits:
- Domestic: Maximum 14 consecutive hours
- International: Maximum 20 consecutive hours

#### 3. Actual Arrival Time
The `ActualArrival` field enables accurate calculation of:
- Duty time for flight attendants
- Rest time between flights
- Total time away from base

---

## Business Logic

### Functions

#### fn_CalculateCrewHours
```sql
fn_CalculateCrewHours(@CrewID INT, @HoursPeriod INT) RETURNS DECIMAL(7,2)
```
Calculates total flight hours for a crew member within a specified time period.
- Parameters:
  - @CrewID: Crew member ID
  - @HoursPeriod: Time window in hours (168, 672, or 8760 for 365 days)
- Returns: Total flight hours (decimal)
- Logic: Sums FlightDuration from all completed/in-flight assignments within the time window

#### fn_CheckHourLimits
```sql
fn_CheckHourLimits(@CrewID INT) RETURNS TABLE
```
Checks if a pilot exceeds FAA hour limitations (14 CFR Part 117 and 121.467).
- Returns table with:
  - Hours in last 168h, 672h, and 365 days
  - ExceedsLimits flag (1 if any limit exceeded)
  - LimitStatus description
- Pilot Limits Checked:
  - 60 hours in 168 hours (7 days)
  - 100 hours in 672 hours (28 days)
  - 190 hours in 672 hours (alternate limit)
  - 1,000 hours in 365 days (1 year)

#### fn_CheckFADutyLimits
```sql
fn_CheckFADutyLimits(@CrewID INT, @FlightID INT) RETURNS TABLE
```
Checks if a flight attendant would exceed duty time limits or rest requirements.
- Returns table with:
  - Flight duration in hours
  - ExceedsDutyLimit flag (1 if exceeds 14h domestic or 20h international)
  - RestHoursSinceLastFlight
  - InsufficientRest flag (1 if less than 9 hours rest)

#### fn_CalculateRestTime
```sql
fn_CalculateRestTime(@CrewID INT, @NewFlightID INT) RETURNS INT
```
Calculates hours of rest between last flight and proposed new flight.
- Returns: Hours of rest, or -1 if no previous flight

### Stored Procedures

#### sp_ScheduleCrew
```sql
sp_ScheduleCrew @FlightID INT
```
Intelligently assigns crew to a scheduled flight with full validation.

**Logic:**
1. Verify flight is in Scheduled status
2. Get departure airport for crew matching
3. Find 2 available pilots at departure airport:
   - Within hour limits (via fn_CheckHourLimits)
   - Adequate rest time
   - Prioritize senior pilots
   - Ensure at least 1 senior (captain)
4. Find 3 available flight attendants at departure airport:
   - Within duty time limits (via fn_CheckFADutyLimits)
   - Adequate rest time (9+ hours)
   - Prioritize senior FAs
   - Ensure at least 1 senior
5. Validate crew composition meets requirements
6. Insert assignments atomically (with transaction)

**Error Handling:**
- Raises error if flight not found or not scheduled
- Rolls back if insufficient qualified crew
- Rolls back if crew composition requirements not met

#### sp_UpdateFlightStatus
```sql
sp_UpdateFlightStatus @FlightID INT, @NewStatus NVARCHAR(20)
```
Updates flight status and timestamps.

**Logic:**
- When status changes to InFlight: Sets ActualDeparture to current time
- When status changes to Landed: Sets ActualArrival to current time
- Validates status transition

### Views

#### vw_AvailableCrew
Shows crew members who are:
- Active (IsActive = 1)
- Within regulatory hour limits
- Includes calculated hours for all time windows
- Shows limit status

#### vw_FlightCrew
Shows crew assignments with full flight and crew details including:
- Flight information
- Departure/destination cities
- Crew names and roles
- Seniority levels
- Flight hours

---

## Regulatory Compliance

### 14 CFR Part 117 and 121.467 Implementation

#### Pilot Flight Time Limitations

| Regulation | Limit | Time Period | Implementation |
|------------|-------|-------------|----------------|
| 121.467(b)(1) | 60 hours | 168 consecutive hours (7 days) | fn_CheckHourLimits checks Hours168 ≤ 60 |
| 121.467(b)(2) | 100 hours | 672 consecutive hours (28 days) | fn_CheckHourLimits checks Hours672 ≤ 100 |
| 121.467(b)(3) | 190 hours | 672 consecutive hours (alternate) | fn_CheckHourLimits checks Hours672 ≤ 190 |
| 121.467(b)(4) | 1,000 hours | 365 consecutive days (1 year) | fn_CheckHourLimits checks Hours365Days ≤ 1000 |

#### Flight Attendant Duty Time Limitations

| Regulation | Limit | Flight Type | Implementation |
|------------|-------|-------------|----------------|
| 14 CFR Part 117 | 14 consecutive hours | Domestic | fn_CheckFADutyLimits checks IsInternational=0 AND FlightHours ≤ 14 |
| 14 CFR Part 117 | 20 consecutive hours | International | fn_CheckFADutyLimits checks IsInternational=1 AND FlightHours ≤ 20 |
| Rest Requirement | 9 consecutive hours | Between flights | fn_CalculateRestTime ensures ≥ 9 hours between flights |

### Compliance Validation Points

1. **Pre-Assignment Validation**: sp_ScheduleCrew validates all limits before assignment
2. **Available Crew View**: vw_AvailableCrew only shows crew within limits
3. **Compliance Reporting**: Report 2 identifies crew at risk or exceeding limits
4. **Real-time Calculation**: Dynamic hour calculation ensures current compliance status

---

## Security Implementation

### Data Encryption

**Symmetric Key Encryption for SSN:**
```sql
-- Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword!123';

-- Certificate
CREATE CERTIFICATE CrewSSNCert
WITH SUBJECT = 'Certificate for SSN Encryption';

-- Symmetric Key (AES-256)
CREATE SYMMETRIC KEY CrewSSNKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CrewSSNCert;
```

**Usage:**
- Encryption: `ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), 'SSN-Value')`
- Decryption: `DECRYPTBYKEY(EncryptedSSN)`

### Role-Based Access Control

**Roles:**
1. **StationManager**: Schedule crew, view flights and crew
2. **FlightOps**: View flights, crew assignments, and in-flight operations
3. **Compliance**: Read-only access to all data for regulatory reporting
4. **HR**: Update crew information, view hours for payroll

**Permissions:**
- GRANT SELECT, INSERT, UPDATE on appropriate tables per role
- Compliance has SELECT-only on all tables
- Station managers can INSERT into CrewAssignments (scheduling)
- HR can UPDATE Crew table

### Best Practices
- Store master key password securely (not in scripts)
- Regularly rotate encryption keys
- Audit access to encrypted data
- Use TDE (Transparent Data Encryption) for database-level encryption
- Implement TLS for data in transit

---

## High Availability Architecture

### 99.9999% Uptime Design (5.26 minutes downtime/year)

#### Multi-Tier Architecture

```
                            [Load Balancer - Layer 7]
                                      |
                    +----------------+----------------+
                    |                                 |
          [App Server 1]                     [App Server 2]
          - Connection Pool                  - Connection Pool
          - Stateless API                    - Stateless API
                    |                                 |
                    +----------------+----------------+
                                     |
                        [SQL Server Always On AG]
                                     |
                    +----------------+----------------+
                    |                |                |
            [Primary Replica]  [Sync Secondary] [Async Secondary]
            - Read/Write       - Automatic      - DR Site
            - Auto Failover    Failover         - Manual Failover
                    |                |                |
            [Shared Storage]  [Shared Storage] [Remote Storage]
```

#### Components

**1. Load Balancer**
- Hardware load balancer (F5, Citrix NetScaler) or cloud-based (AWS ALB, Azure Load Balancer)
- Health check endpoints on application servers
- Automatic failover if app server unhealthy
- SSL termination
- Geographic distribution support

**2. Application Servers**
- Minimum 2 active servers (N+1 redundancy)
- Stateless design - no session affinity required
- Connection pooling to database
- Automatic retry logic with exponential backoff
- Circuit breaker pattern for database failures

**3. SQL Server Always On Availability Groups**
- Primary replica: Read-write operations
- Synchronous secondary: Automatic failover partner
  - Zero data loss (synchronous commit)
  - Automatic failover in seconds
- Asynchronous secondary: Disaster recovery
  - Different datacenter/region
  - Manual failover if primary site fails
  - Minimal data loss (seconds of transactions)

**4. Networking**
- Redundant network paths
- Multi-homed servers
- Dedicated heartbeat network for cluster
- VPN tunnels between sites

**5. Monitoring & Alerting**
- 24/7 monitoring of all components
- Automated alerts for:
  - Server health degradation
  - Database failover events
  - High response times
  - Connection pool exhaustion
  - Replication lag
- Automated restart procedures

#### Disaster Recovery

**RPO (Recovery Point Objective):** < 1 minute
- Synchronous replication to secondary replica
- Transaction log backups every 15 minutes

**RTO (Recovery Time Objective):** < 2 minutes
- Automatic failover to synchronous secondary
- Manual failover to asynchronous secondary if needed

**Backup Strategy:**
- Full backup: Daily at 2 AM
- Differential backup: Every 4 hours
- Transaction log backup: Every 15 minutes
- Backups replicated to remote storage (Azure Blob, AWS S3)
- Monthly backup verification and restore testing

#### Regional Distribution

For global operations:
```
[Region 1 - Americas]        [Region 2 - Europe]         [Region 3 - Asia-Pacific]
- Primary AG                 - Primary AG                - Primary AG
- Local read replicas        - Local read replicas       - Local read replicas
- Cross-region replication   - Cross-region replication  - Cross-region replication
```

- Each region has independent database cluster
- Read replicas in same region for reporting queries
- Cross-region replication for disaster recovery
- Geo-routing based on airport location

#### Scalability Considerations

**Vertical Scaling:**
- Enterprise-class servers (96+ cores, 512GB+ RAM)
- NVMe SSD storage for database files
- 10Gbps+ network interfaces

**Horizontal Scaling:**
- Read-only routing to secondary replicas for reporting
- Sharding by airport region if needed
- Microservices architecture for application tier

**Database Optimization:**
- Indexed views for complex reports
- Columnstore indexes for historical data
- Table partitioning for Flights and CrewAssignments by month
- Automatic statistics updates
- Query Store enabled for performance monitoring

---

## Installation and Setup

### Prerequisites
- SQL Server 2019 or later
- SQL Server Management Studio (SSMS)
- Administrative access to SQL Server instance

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/prachwal/odloty.git
cd odloty
```

2. **Execute scripts in order**

```sql
-- Script 1: Reset (if needed)
:r 00_reset_crew_database.sql

-- Script 2: Create database and schema
:r 01_create_crew_database.sql

-- Script 3: Insert sample data
:r 02_insert_crew_data.sql

-- Script 4: Create business logic
:r 03_crew_logic.sql

-- Script 5: Verify reports
:r 05_reports.sql
```

3. **Verify installation**
```sql
-- Check database exists
SELECT name FROM sys.databases WHERE name = 'CrewSchedulingDB';

-- Check tables created
USE CrewSchedulingDB;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Check functions and procedures
SELECT name, type_desc FROM sys.objects 
WHERE type IN ('FN', 'IF', 'TF', 'P') AND name LIKE '%Crew%' OR name LIKE '%fn_%';
```

### Configuration

**Update encryption password in production:**
```sql
-- Change master key password
USE CrewSchedulingDB;
ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'YourProductionPassword!';
```

**Create database users and assign roles:**
```sql
-- Example: Create login and user for station manager
CREATE LOGIN stationmgr1 WITH PASSWORD = 'SecurePassword!';
USE CrewSchedulingDB;
CREATE USER stationmgr1 FOR LOGIN stationmgr1;
ALTER ROLE StationManager ADD MEMBER stationmgr1;
```

---

## Usage Guide

### Common Operations

#### 1. Schedule Crew for a Flight

```sql
-- Check flight details
SELECT * FROM Flights WHERE FlightID = 89;

-- View available crew at departure airport
SELECT * FROM vw_AvailableCrew 
WHERE BaseCity = (SELECT City FROM Airports A JOIN Flights F ON A.AirportID = F.DepartureAirportID WHERE F.FlightID = 89);

-- Schedule the crew
EXEC sp_ScheduleCrew @FlightID = 89;

-- Verify assignment
SELECT * FROM vw_FlightCrew WHERE FlightID = 89;
```

#### 2. Update Flight Status

```sql
-- Flight departs
EXEC sp_UpdateFlightStatus @FlightID = 89, @NewStatus = 'InFlight';

-- Flight lands
EXEC sp_UpdateFlightStatus @FlightID = 89, @NewStatus = 'Landed';
```

#### 3. Check Crew Hour Limits

```sql
-- Check specific crew member
SELECT * FROM dbo.fn_CheckHourLimits(1);

-- Check all pilots approaching limits
SELECT C.CrewID, C.FirstName, C.LastName, HL.*
FROM Crew C
CROSS APPLY dbo.fn_CheckHourLimits(C.CrewID) HL
WHERE C.CrewTypeID = 2  -- Pilots
  AND (HL.Hours168 > 54 OR HL.Hours672 > 90 OR HL.Hours365Days > 900);
```

#### 4. Generate Payroll Report

```sql
-- Get hours for October 2025
SELECT 
    C.CrewID,
    C.FirstName + ' ' + C.LastName AS EmployeeName,
    SUM(F.FlightDuration / 60.0) AS TotalHours,
    COUNT(*) AS FlightsWorked
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
WHERE YEAR(F.ScheduledDeparture) = 2025
  AND MONTH(F.ScheduledDeparture) = 10
  AND F.StatusID = 3  -- Landed
GROUP BY C.CrewID, C.FirstName, C.LastName
ORDER BY TotalHours DESC;
```

### Troubleshooting

**Problem: sp_ScheduleCrew fails with "Insufficient qualified crew"**
- Solution: Check vw_AvailableCrew for the departure airport. May need to:
  - Wait for crew to get adequate rest
  - Transfer crew from other airports
  - Hire additional crew

**Problem: Crew member shows as exceeding limits but shouldn't**
- Solution: Verify ActualDeparture and ActualArrival times are correct. Run:
```sql
SELECT CA.AssignmentID, F.FlightID, F.FlightNumber, F.ActualDeparture, F.ActualArrival, F.FlightDuration
FROM CrewAssignments CA
JOIN Flights F ON CA.FlightID = F.FlightID
WHERE CA.CrewID = <CrewID>
  AND F.ActualDeparture >= DATEADD(HOUR, -672, GETDATE())
ORDER BY F.ActualDeparture DESC;
```

---

## Testing

### Test Scripts

Execute `04_test_crew_logic.sql` to run comprehensive tests:

```sql
:r 04_test_crew_logic.sql
```

### Test Coverage

1. **Unit Tests**
   - fn_CalculateCrewHours with various time periods
   - fn_CheckHourLimits for pilots exceeding each limit type
   - fn_CheckFADutyLimits for domestic and international flights
   - fn_CalculateRestTime for rest period validation
   - vw_AvailableCrew view filtering
   - vw_FlightCrew view data accuracy

2. **Integration Tests**
   - End-to-end scheduling workflow
   - Status update propagation
   - Hour calculation after assignments
   - Concurrent scheduling attempts

3. **Performance Tests**
   - sp_ScheduleCrew execution time (target: <2 seconds)
   - View query performance with JOINs
   - Hour calculation performance for large datasets

### Sample Test Data

The database includes:
- 50 crew members (20 pilots, 30 flight attendants)
- 10 airports (NYC, Burlington, Chicago, LA, Miami, Seattle, Denver, Boston, SF, Dallas)
- 10 airlines
- 100 flights (85 historical, 15 scheduled/in-flight)
- 200+ crew assignments covering various scenarios:
  - Pilots approaching/exceeding hour limits
  - Flight attendants with insufficient rest
  - International vs domestic flights
  - Various seniority levels and locations

---

## Additional Resources

- [Federal Aviation Regulations 14 CFR Part 117](https://www.ecfr.gov/current/title-14/chapter-I/subchapter-G/part-117)
- [14 CFR 121.467 - Flight Time Limitations](https://www.ecfr.gov/current/title-14/section-121.467)
- [SQL Server Always On Availability Groups](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server)
- [SQL Server Encryption](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/sql-server-encryption)

---

## License

This project is provided as-is for educational and technical audition purposes.

---

## Contact

For questions or issues, please contact the development team or open an issue in the repository.

---

*Last Updated: November 2025*
*Version: 2.0 - Updated with dynamic hour calculation and enhanced regulatory compliance*
