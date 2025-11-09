-- =============================================
-- Phase 5: Reports from Task
-- =============================================
-- This script contains 4 SQL queries as required by zadanie.md
-- Plus architecture diagram description
-- =============================================

USE CrewSchedulingDB;
GO

-- Report 1: Crew currently in flight
PRINT 'Report 1: Crew currently in flight';
SELECT C.CrewID, C.FirstName, C.LastName, F.FlightID, F.FlightNumber,
       F.ScheduledDeparture AS DepartureTime, DATEADD(MINUTE, F.FlightDuration, F.ScheduledDeparture) AS ArrivalTime, CA.RoleID
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
WHERE F.StatusID = 2
ORDER BY F.FlightID, CA.RoleID;
GO

-- Report 2: Crew exceeding hour limits
PRINT 'Report 2: Crew exceeding hour limits';
SELECT C.CrewID, C.FirstName, C.LastName, C.HoursLast40 AS TotalHours,
       dbo.fn_CheckHourLimits(C.CrewID) AS WithinLimits
FROM Crew C
WHERE dbo.fn_CheckHourLimits(C.CrewID) = 0  -- 0 means exceeding limits
ORDER BY C.HoursLast40 DESC;
GO

-- Report 3: Monthly hours worked by crew
PRINT 'Report 3: Monthly hours worked by crew';
SELECT C.CrewID, C.FirstName, C.LastName,
       YEAR(F.ScheduledDeparture) AS Year,
       MONTH(F.ScheduledDeparture) AS Month,
       SUM(DATEDIFF(HOUR, F.ScheduledDeparture, DATEADD(MINUTE, F.FlightDuration, F.ScheduledDeparture))) AS MonthlyHours
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
WHERE F.StatusID IN (3, 2)  -- Completed or current flights
GROUP BY C.CrewID, C.FirstName, C.LastName, YEAR(F.ScheduledDeparture), MONTH(F.ScheduledDeparture)
ORDER BY C.CrewID, Year, Month;
GO

-- Report 4: Schedule crew for a specific flight (demonstration)
PRINT 'Report 4: Schedule crew for flight (example for FlightID 92)';
-- First show available crew
SELECT TOP 5 C.CrewID, C.FirstName, C.LastName, C.BaseAirportID,
       dbo.fn_CalculateRestTime(C.CrewID, 92) AS RestTimeHours
FROM Crew C
WHERE C.BaseAirportID = (SELECT DepartureAirportID FROM Flights WHERE FlightID = 92)
  AND dbo.fn_CheckHourLimits(C.CrewID) = 1  -- Within limits
  AND dbo.fn_CalculateRestTime(C.CrewID, 92) >= 12  -- Minimum rest
ORDER BY RestTimeHours DESC;
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