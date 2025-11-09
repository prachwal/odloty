-- =============================================
-- Phase 5: Reports from Task (Updated with new functions)
-- =============================================
-- This script contains 4 SQL queries as required by zadanie.md
-- Updated to use new dynamic hour calculation functions
-- =============================================

USE CrewSchedulingDB;
GO

-- Report 1: Crew currently in flight
PRINT 'Report 1: Crew currently in flight';
PRINT '================================================';
SELECT 
    C.CrewID, 
    C.FirstName + ' ' + C.LastName AS CrewName,
    CT.CrewTypeName,
    SL.SeniorityName,
    F.FlightID, 
    F.FlightNumber,
    DepAir.City AS DepartureCity,
    DestAir.City AS DestinationCity,
    F.ActualDeparture AS DepartureTime, 
    DATEADD(MINUTE, F.FlightDuration, F.ActualDeparture) AS EstimatedArrival,
    F.FlightDuration / 60.0 AS FlightHours,
    R.RoleName AS Role
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
JOIN Airports DepAir ON F.DepartureAirportID = DepAir.AirportID
JOIN Airports DestAir ON F.DestinationAirportID = DestAir.AirportID
JOIN Roles R ON CA.RoleID = R.RoleID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID
WHERE F.StatusID = 2  -- InFlight
ORDER BY F.FlightID, R.RoleID DESC, C.LastName;
GO

-- Report 2: Crew exceeding or approaching hour limits (14 CFR Part 117 and 121.467)
PRINT '';
PRINT 'Report 2: Crew exceeding or approaching regulatory hour limits';
PRINT '================================================';
SELECT 
    C.CrewID,
    C.FirstName + ' ' + C.LastName AS CrewName,
    HL.CrewTypeName,
    HL.Hours168 AS [Hours Last 7 Days],
    HL.Hours672 AS [Hours Last 28 Days],
    HL.Hours365Days AS [Hours Last 365 Days],
    HL.ExceedsLimits AS [Exceeds Limits?],
    HL.LimitStatus AS [Limit Status],
    CASE 
        WHEN HL.CrewTypeName = 'Pilot' THEN 
            CASE
                WHEN HL.Hours168 > 54 THEN 'WARNING: Approaching 60h/7d limit'
                WHEN HL.Hours672 > 90 THEN 'WARNING: Approaching 100h/28d limit'
                WHEN HL.Hours672 > 180 THEN 'WARNING: Approaching 190h/28d limit'
                WHEN HL.Hours365Days > 900 THEN 'WARNING: Approaching 1000h/yr limit'
                ELSE 'OK'
            END
        ELSE 'See duty time per flight'
    END AS [Warning Status]
FROM Crew C
CROSS APPLY dbo.fn_CheckHourLimits(C.CrewID) HL
WHERE C.IsActive = 1
    AND (HL.ExceedsLimits = 1  -- Already exceeding
        OR (HL.CrewTypeName = 'Pilot' AND (HL.Hours168 > 54 OR HL.Hours672 > 90 OR HL.Hours365Days > 900)))  -- Approaching limit
ORDER BY HL.ExceedsLimits DESC, HL.Hours672 DESC;
GO

-- Report 3: Monthly hours worked by crew (for payroll)
PRINT '';
PRINT 'Report 3: Monthly hours worked per employee (for payroll)';
PRINT '================================================';
SELECT 
    C.CrewID,
    C.FirstName + ' ' + C.LastName AS CrewName,
    CT.CrewTypeName,
    SL.SeniorityName,
    YEAR(F.ScheduledDeparture) AS Year,
    MONTH(F.ScheduledDeparture) AS Month,
    DATENAME(MONTH, F.ScheduledDeparture) AS MonthName,
    COUNT(CA.AssignmentID) AS FlightsWorked,
    SUM(F.FlightDuration / 60.0) AS TotalHoursWorked,
    AVG(F.FlightDuration / 60.0) AS AvgFlightHours
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID
WHERE F.StatusID IN (2, 3)  -- InFlight or Landed (completed work)
    AND F.ActualDeparture IS NOT NULL
GROUP BY C.CrewID, C.FirstName, C.LastName, CT.CrewTypeName, SL.SeniorityName,
         YEAR(F.ScheduledDeparture), MONTH(F.ScheduledDeparture), DATENAME(MONTH, F.ScheduledDeparture)
ORDER BY Year DESC, Month DESC, TotalHoursWorked DESC;
GO

-- Report 4: Available crew for scheduling a flight (with regulatory compliance check)
PRINT '';
PRINT 'Report 4: Available crew for scheduling (example for NYC departures)';
PRINT '================================================';
-- This report shows crew available at NYC airport who are within regulatory limits
SELECT 
    AC.CrewID,
    AC.FirstName + ' ' + AC.LastName AS CrewName,
    AC.CrewTypeName,
    AC.SeniorityName,
    AC.BaseCity,
    AC.Hours168 AS [Hours Last 7 Days],
    AC.Hours672 AS [Hours Last 28 Days],
    AC.Hours365Days AS [Hours Last Year],
    AC.LimitStatus AS [Regulatory Status]
FROM vw_AvailableCrew AC
WHERE AC.BaseCity = 'New York'  -- Example: NYC airport
ORDER BY AC.CrewTypeID DESC, AC.SeniorityID DESC, AC.CrewID;
GO

PRINT '';
PRINT '================================================';
PRINT 'All reports completed successfully.';
PRINT '================================================';
GO

-- Architecture Diagram Description
/*
Crew Scheduling System Architecture
====================================

Database: CrewSchedulingDB (SQL Server 2019)

Tables:
- Crew (CrewID PK, encrypted SSN, personal info, hours tracking)
- Flights (FlightID PK, AirlineID FK, airports, times, status)
- Airlines (AirlineID PK, name)
- Airports (AirportID PK, code, city)
- CrewAssignments (composite PK: CrewID+FlightID, role)

Views:
- vw_AvailableCrew: Crew with current status and availability
- vw_FlightCrew: Assigned crew per flight with details

Functions:
- fn_CheckHourLimits(CrewID): Returns 1 if within 40h/week limit, 0 if exceeding
- fn_CalculateRestTime(CrewID, FlightID): Calculates rest hours before flight

Procedures:
- sp_ScheduleCrew(FlightID): Assigns available crew to scheduled flight
- sp_UpdateFlightStatus(FlightID, NewStatus): Updates flight status

Triggers:
- trg_UpdateCrewHours: Updates crew hours after assignment (AFTER INSERT on CrewAssignments)
- trg_BeforeAssignment: Validates crew availability and rest time (BEFORE INSERT on CrewAssignments)

Security:
- SYMMETRIC KEY for SSN encryption
- CERTIFICATE for key protection
- ROLE-based permissions (CrewScheduler role)

Data Flow:
1. Flights inserted with 'Scheduled' status
2. sp_ScheduleCrew called -> triggers validate -> assignments inserted -> hours updated
3. Flight status updated via sp_UpdateFlightStatus
4. Reports query views and functions for business intelligence

Encryption: SSN fields encrypted at rest using SQL Server encryption
*/
PRINT 'Architecture diagram description included above as comments';
GO