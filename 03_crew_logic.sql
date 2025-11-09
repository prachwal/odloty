-- =============================================
-- Script: 03_crew_logic.sql
-- Description: Implement business logic for CrewSchedulingDB (Phase 3)
-- This script creates stored procedures, functions, views, and triggers for crew scheduling and validation.
-- Idempotent: Drops existing objects before creating.
-- =============================================

USE CrewSchedulingDB;
GO

-- Drop existing objects if they exist
DROP PROCEDURE IF EXISTS sp_ScheduleCrew;
DROP PROCEDURE IF EXISTS sp_UpdateFlightStatus;
DROP FUNCTION IF EXISTS fn_CheckHourLimits;
DROP FUNCTION IF EXISTS fn_CalculateRestTime;
DROP VIEW IF EXISTS vw_AvailableCrew;
DROP VIEW IF EXISTS vw_FlightCrew;
DROP TRIGGER IF EXISTS trg_AfterAssignment;
DROP TRIGGER IF EXISTS trg_BeforeAssignment;
GO

-- =============================================
-- Functions
-- =============================================

-- Function to check if a crew member exceeds hour limits
CREATE FUNCTION fn_CheckHourLimits (@CrewID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @CrewTypeID INT, @HoursLast40 INT, @HoursLast7 INT, @HoursLast28 INT;
    DECLARE @Exceeds BIT = 0;

    SELECT @CrewTypeID = CrewTypeID, @HoursLast40 = HoursLast40, @HoursLast7 = HoursLast7, @HoursLast28 = HoursLast28
    FROM Crew WHERE CrewID = @CrewID AND IsActive = 1;

    IF @CrewTypeID = 2 -- Pilot
    BEGIN
        IF @HoursLast40 > 100 OR @HoursLast7 > 60 OR @HoursLast28 > 190
            SET @Exceeds = 1;
    END
    ELSE IF @CrewTypeID = 1 -- FA
    BEGIN
        IF @HoursLast7 > 14 OR @HoursLast28 > 20  -- Simplified, assuming domestic; international would be 20/30
            SET @Exceeds = 1;
    END

    RETURN @Exceeds;
END;
GO

-- Function to calculate rest time between flights for FA
CREATE FUNCTION fn_CalculateRestTime (@CrewID INT, @NewFlightID INT)
RETURNS INT -- Returns rest time in hours, or -1 if no previous flight
AS
BEGIN
    DECLARE @LastFlightEnd DATETIME2, @NewFlightStart DATETIME2, @RestHours INT;

    -- Find the last flight end time for this crew
    SELECT TOP 1 @LastFlightEnd = DATEADD(MINUTE, F.FlightDuration, F.ActualDeparture)
    FROM CrewAssignments CA
    JOIN Flights F ON CA.FlightID = F.FlightID
    WHERE CA.CrewID = @CrewID AND F.StatusID = 3
    ORDER BY F.ActualDeparture DESC;

    -- New flight start
    SELECT @NewFlightStart = ScheduledDeparture FROM Flights WHERE FlightID = @NewFlightID;

    IF @LastFlightEnd IS NULL
        RETURN -1; -- No previous flight

    SET @RestHours = DATEDIFF(HOUR, @LastFlightEnd, @NewFlightStart);
    RETURN @RestHours;
END;
GO

-- =============================================
-- Views
-- =============================================

-- View for available crew in a city without exceeding limits
CREATE VIEW vw_AvailableCrew AS
SELECT C.CrewID, C.FirstName, C.LastName, A.City AS BaseCity, C.CrewTypeID, C.SeniorityID
FROM Crew C
JOIN Airports A ON C.BaseAirportID = A.AirportID
WHERE C.IsActive = 1 AND dbo.fn_CheckHourLimits(C.CrewID) = 0;
GO

-- View for crew assigned to a flight
CREATE VIEW vw_FlightCrew AS
SELECT F.FlightID, F.FlightNumber, F.ScheduledDeparture, CA.CrewID, C.FirstName, C.LastName, CA.RoleID
FROM Flights F
JOIN CrewAssignments CA ON F.FlightID = CA.FlightID
JOIN Crew C ON CA.CrewID = C.CrewID;
GO

-- =============================================
-- Stored Procedures
-- =============================================

-- Procedure to schedule crew for a flight
CREATE PROCEDURE sp_ScheduleCrew @FlightID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DepartureAirportID INT, @DepartureCity NVARCHAR(50), @FlightDuration INT;
    DECLARE @PilotCount INT = 0, @CabinCount INT = 0;
    DECLARE @SeniorPilotCount INT = 0, @SeniorCabinCount INT = 0;

    SELECT @DepartureAirportID = F.DepartureAirportID, @DepartureCity = A.City, @FlightDuration = F.FlightDuration
    FROM Flights F
    JOIN Airports A ON F.DepartureAirportID = A.AirportID
    WHERE F.FlightID = @FlightID AND F.StatusID = 1;

    IF @DepartureAirportID IS NULL
    BEGIN
        RAISERROR('Flight not found or not scheduled.', 16, 1);
        RETURN;
    END

    -- Find and assign 2 pilots (at least 1 senior)
    DECLARE PilotCursor CURSOR FOR
    SELECT TOP 2 CrewID FROM vw_AvailableCrew
    WHERE BaseCity = @DepartureCity AND CrewTypeID = 2
    ORDER BY SeniorityID DESC; -- Prefer seniors

    DECLARE @CrewID INT;
    OPEN PilotCursor;
    FETCH NEXT FROM PilotCursor INTO @CrewID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt)
        VALUES (@FlightID, @CrewID, 1, GETDATE());

        SET @PilotCount = @PilotCount + 1;
        IF (SELECT SeniorityID FROM Crew WHERE CrewID = @CrewID) = 3
            SET @SeniorPilotCount = @SeniorPilotCount + 1;

        FETCH NEXT FROM PilotCursor INTO @CrewID;
    END
    CLOSE PilotCursor;
    DEALLOCATE PilotCursor;

    -- Find and assign 3 cabin crew (at least 1 senior)
    DECLARE CabinCursor CURSOR FOR
    SELECT TOP 3 CrewID FROM vw_AvailableCrew
    WHERE BaseCity = @DepartureCity AND CrewTypeID = 1
    ORDER BY SeniorityID DESC;

    OPEN CabinCursor;
    FETCH NEXT FROM CabinCursor INTO @CrewID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt)
        VALUES (@FlightID, @CrewID, 2, GETDATE());

        SET @CabinCount = @CabinCount + 1;
        IF (SELECT SeniorityID FROM Crew WHERE CrewID = @CrewID) = 3
            SET @SeniorCabinCount = @SeniorCabinCount + 1;

        FETCH NEXT FROM CabinCursor INTO @CrewID;
    END
    CLOSE CabinCursor;
    DEALLOCATE CabinCursor;

    -- Validate assignment
    IF @PilotCount < 2 OR @SeniorPilotCount < 1 OR @CabinCount < 3 OR @SeniorCabinCount < 1
    BEGIN
        -- Rollback assignments if invalid
        DELETE FROM CrewAssignments WHERE FlightID = @FlightID;
        RAISERROR('Insufficient qualified crew available.', 16, 1);
        RETURN;
    END

    PRINT 'Crew scheduled successfully for FlightID: ' + CAST(@FlightID AS NVARCHAR(10));
END;
GO

-- Procedure to update flight status
CREATE PROCEDURE sp_UpdateFlightStatus @FlightID INT, @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StatusID TINYINT;

    IF @NewStatus = 'Scheduled' SET @StatusID = 1;
    ELSE IF @NewStatus = 'InFlight' SET @StatusID = 2;
    ELSE IF @NewStatus = 'Landed' SET @StatusID = 3;
    ELSE
    BEGIN
        RAISERROR('Invalid status.', 16, 1);
        RETURN;
    END

    UPDATE Flights
    SET StatusID = @StatusID,
        ActualDeparture = CASE WHEN @StatusID = 2 AND ActualDeparture IS NULL THEN GETDATE() ELSE ActualDeparture END
    WHERE FlightID = @FlightID;

    PRINT 'Flight status updated to ' + @NewStatus + ' for FlightID: ' + CAST(@FlightID AS NVARCHAR(10));
END;
GO

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update hours after assignment
CREATE TRIGGER trg_AfterAssignment
ON CrewAssignments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CrewID INT, @FlightDuration INT;

    SELECT @CrewID = i.CrewID, @FlightDuration = F.FlightDuration
    FROM inserted i
    JOIN Flights F ON i.FlightID = F.FlightID;

    UPDATE Crew
    SET HoursLast40 = HoursLast40 + @FlightDuration,
        HoursLast7 = HoursLast7 + @FlightDuration,
        HoursLast28 = HoursLast28 + @FlightDuration
    WHERE CrewID = @CrewID;
END;
GO

-- Trigger to validate before assignment
CREATE TRIGGER trg_BeforeAssignment
ON CrewAssignments
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FlightID INT, @CrewID INT, @RoleID NVARCHAR(10), @DepartureAirportID INT;

    SELECT @FlightID = i.FlightID, @CrewID = i.CrewID, @RoleID = i.RoleID
    FROM inserted i;

    SELECT @DepartureAirportID = DepartureAirportID FROM Flights WHERE FlightID = @FlightID;

    -- Check if crew is in the right airport
    IF NOT EXISTS (SELECT 1 FROM Crew WHERE CrewID = @CrewID AND BaseAirportID = @DepartureAirportID AND IsActive = 1)
    BEGIN
        RAISERROR('Crew not available in departure city.', 16, 1);
        RETURN;
    END

    -- Check hour limits
    IF dbo.fn_CheckHourLimits(@CrewID) = 1
    BEGIN
        RAISERROR('Crew exceeds hour limits.', 16, 1);
        RETURN;
    END

    -- If all checks pass, insert
    INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt)
    SELECT FlightID, CrewID, RoleID, GETDATE() FROM inserted;  -- Use GETDATE() for AssignedAt
END;
GO

PRINT 'Business logic implemented successfully for Phase 3.';
GO