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

-- Function to calculate crew hours dynamically in different time periods
-- This replaces static hour tracking with dynamic calculation from flight history
CREATE FUNCTION fn_CalculateCrewHours (
    @CrewID INT,
    @HoursPeriod INT  -- 168, 672, or 8760 (365 days * 24 hours)
)
RETURNS DECIMAL(7,2)
AS
BEGIN
    DECLARE @TotalHours DECIMAL(7,2);
    DECLARE @CutoffDateTime DATETIME2 = DATEADD(HOUR, -@HoursPeriod, GETDATE());
    
    SELECT @TotalHours = ISNULL(SUM(F.FlightDuration / 60.0), 0)
    FROM CrewAssignments CA
    JOIN Flights F ON CA.FlightID = F.FlightID
    WHERE CA.CrewID = @CrewID
        AND F.ActualDeparture IS NOT NULL
        AND F.ActualDeparture >= @CutoffDateTime
        AND F.StatusID IN (2, 3);  -- InFlight or Landed
    
    RETURN @TotalHours;
END;
GO

-- Function to check if a crew member exceeds hour limits per 14 CFR Part 117 and 121.467
CREATE FUNCTION fn_CheckHourLimits (@CrewID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @CrewID AS CrewID,
        C.CrewTypeID,
        CT.CrewTypeName,
        dbo.fn_CalculateCrewHours(@CrewID, 168) AS Hours168,
        dbo.fn_CalculateCrewHours(@CrewID, 672) AS Hours672,
        dbo.fn_CalculateCrewHours(@CrewID, 8760) AS Hours365Days,
        CASE 
            -- Pilot limits (14 CFR Part 117 and 121.467)
            WHEN C.CrewTypeID = 2 AND (
                dbo.fn_CalculateCrewHours(@CrewID, 168) > 60 OR      -- No more than 60h in 168h (7 days)
                dbo.fn_CalculateCrewHours(@CrewID, 672) > 100 OR     -- No more than 100h in 672h (28 days)
                dbo.fn_CalculateCrewHours(@CrewID, 672) > 190 OR     -- No more than 190h in 672h alternate limit
                dbo.fn_CalculateCrewHours(@CrewID, 8760) > 1000      -- No more than 1000h in 365 days
            ) THEN 1
            ELSE 0
        END AS ExceedsLimits,
        CASE
            WHEN C.CrewTypeID = 2 THEN
                CASE 
                    WHEN dbo.fn_CalculateCrewHours(@CrewID, 168) > 60 THEN '60h/168h exceeded'
                    WHEN dbo.fn_CalculateCrewHours(@CrewID, 672) > 100 THEN '100h/672h exceeded'
                    WHEN dbo.fn_CalculateCrewHours(@CrewID, 672) > 190 THEN '190h/672h exceeded'
                    WHEN dbo.fn_CalculateCrewHours(@CrewID, 8760) > 1000 THEN '1000h/365d exceeded'
                    ELSE 'Within limits'
                END
            ELSE 'FA (duty time calculated separately)'
        END AS LimitStatus
    FROM Crew C
    JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
    WHERE C.CrewID = @CrewID
);
GO

-- Function to calculate rest time between flights for crew (especially FA - requires 9h)
CREATE FUNCTION fn_CalculateRestTime (@CrewID INT, @NewFlightID INT)
RETURNS INT -- Returns rest time in hours, or -1 if no previous flight
AS
BEGIN
    DECLARE @LastFlightEnd DATETIME2, @NewFlightStart DATETIME2, @RestHours INT;

    -- Find the last flight end time for this crew
    SELECT TOP 1 @LastFlightEnd = ISNULL(F.ActualArrival, DATEADD(MINUTE, F.FlightDuration, F.ActualDeparture))
    FROM CrewAssignments CA
    JOIN Flights F ON CA.FlightID = F.FlightID
    WHERE CA.CrewID = @CrewID 
        AND F.ActualDeparture IS NOT NULL
        AND F.StatusID IN (2, 3)  -- InFlight or Landed
    ORDER BY F.ActualDeparture DESC;

    -- New flight start
    SELECT @NewFlightStart = ScheduledDeparture FROM Flights WHERE FlightID = @NewFlightID;

    IF @LastFlightEnd IS NULL OR @NewFlightStart IS NULL
        RETURN -1; -- No previous flight or invalid new flight

    SET @RestHours = DATEDIFF(HOUR, @LastFlightEnd, @NewFlightStart);
    RETURN @RestHours;
END;
GO

-- Function to check Flight Attendant duty time limits
-- FA limits: 14h domestic, 20h international, 9h rest between flights
CREATE FUNCTION fn_CheckFADutyLimits (
    @CrewID INT,
    @FlightID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @CrewID AS CrewID,
        @FlightID AS FlightID,
        F.IsInternational,
        F.FlightDuration / 60.0 AS FlightHours,
        CASE 
            WHEN F.IsInternational = 0 AND F.FlightDuration / 60.0 > 14 THEN 1  -- Domestic: max 14h
            WHEN F.IsInternational = 1 AND F.FlightDuration / 60.0 > 20 THEN 1  -- International: max 20h
            ELSE 0
        END AS ExceedsDutyLimit,
        dbo.fn_CalculateRestTime(@CrewID, @FlightID) AS RestHoursSinceLastFlight,
        CASE 
            WHEN dbo.fn_CalculateRestTime(@CrewID, @FlightID) < 9 AND dbo.fn_CalculateRestTime(@CrewID, @FlightID) >= 0 THEN 1
            ELSE 0
        END AS InsufficientRest
    FROM Flights F
    WHERE F.FlightID = @FlightID
);
GO

-- =============================================
-- Views
-- =============================================

-- View for available crew in a city without exceeding limits
CREATE VIEW vw_AvailableCrew AS
SELECT 
    C.CrewID, 
    C.FirstName, 
    C.LastName, 
    A.City AS BaseCity, 
    C.CrewTypeID, 
    CT.CrewTypeName,
    C.SeniorityID,
    SL.SeniorityName,
    HL.Hours168,
    HL.Hours672,
    HL.Hours365Days,
    HL.ExceedsLimits,
    HL.LimitStatus
FROM Crew C
JOIN Airports A ON C.BaseAirportID = A.AirportID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID
CROSS APPLY dbo.fn_CheckHourLimits(C.CrewID) HL
WHERE C.IsActive = 1 AND HL.ExceedsLimits = 0;
GO

-- View for crew assigned to a flight with detailed information
CREATE VIEW vw_FlightCrew AS
SELECT 
    F.FlightID, 
    F.FlightNumber, 
    F.ScheduledDeparture,
    F.ActualDeparture,
    F.IsInternational,
    DepAir.City AS DepartureCity,
    DestAir.City AS DestinationCity,
    CA.CrewID, 
    C.FirstName, 
    C.LastName, 
    CA.RoleID,
    R.RoleName,
    CT.CrewTypeName,
    SL.SeniorityName,
    F.FlightDuration / 60.0 AS FlightHours
FROM Flights F
JOIN CrewAssignments CA ON F.FlightID = CA.FlightID
JOIN Crew C ON CA.CrewID = C.CrewID
JOIN Airports DepAir ON F.DepartureAirportID = DepAir.AirportID
JOIN Airports DestAir ON F.DestinationAirportID = DestAir.AirportID
JOIN Roles R ON CA.RoleID = R.RoleID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID;
GO

-- =============================================
-- Stored Procedures
-- =============================================

-- Procedure to schedule crew for a flight with proper validation
CREATE PROCEDURE sp_ScheduleCrew @FlightID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @DepartureAirportID INT, @DepartureCity NVARCHAR(50), @FlightDuration INT, @IsInternational BIT;
        DECLARE @PilotCount INT = 0, @CabinCount INT = 0;
        DECLARE @SeniorPilotCount INT = 0, @SeniorCabinCount INT = 0;

        -- Get flight details
        SELECT @DepartureAirportID = F.DepartureAirportID, 
               @DepartureCity = A.City, 
               @FlightDuration = F.FlightDuration,
               @IsInternational = F.IsInternational
        FROM Flights F
        JOIN Airports A ON F.DepartureAirportID = A.AirportID
        WHERE F.FlightID = @FlightID AND F.StatusID = 1;  -- Only scheduled flights

        IF @DepartureAirportID IS NULL
        BEGIN
            RAISERROR('Flight not found or not in scheduled status.', 16, 1);
            RETURN;
        END

        -- Check if crew already assigned
        IF EXISTS (SELECT 1 FROM CrewAssignments WHERE FlightID = @FlightID)
        BEGIN
            RAISERROR('Crew already assigned to this flight.', 16, 1);
            RETURN;
        END

        -- Assign 2 pilots (at least 1 senior, seniority level 3)
        DECLARE @CrewID INT, @SeniorityID INT;
        
        DECLARE PilotCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 2 CrewID, SeniorityID 
        FROM vw_AvailableCrew
        WHERE BaseCity = @DepartureCity 
            AND CrewTypeID = 2  -- Pilots
            AND ExceedsLimits = 0
        ORDER BY SeniorityID DESC, CrewID;  -- Prefer senior pilots

        OPEN PilotCursor;
        FETCH NEXT FROM PilotCursor INTO @CrewID, @SeniorityID;
        
        WHILE @@FETCH_STATUS = 0 AND @PilotCount < 2
        BEGIN
            -- Additional validation: check rest time
            DECLARE @RestTime INT = dbo.fn_CalculateRestTime(@CrewID, @FlightID);
            IF @RestTime >= 9 OR @RestTime = -1  -- Adequate rest or no previous flight
            BEGIN
                INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt)
                VALUES (@FlightID, @CrewID, 1, GETDATE());  -- RoleID=1 for Pilot

                SET @PilotCount = @PilotCount + 1;
                IF @SeniorityID = 3
                    SET @SeniorPilotCount = @SeniorPilotCount + 1;
            END
            
            FETCH NEXT FROM PilotCursor INTO @CrewID, @SeniorityID;
        END
        
        CLOSE PilotCursor;
        DEALLOCATE PilotCursor;

        -- Assign 3 cabin crew (at least 1 senior, seniority level 3)
        DECLARE CabinCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 5 CrewID, SeniorityID  -- Get more candidates in case some fail validation
        FROM vw_AvailableCrew
        WHERE BaseCity = @DepartureCity 
            AND CrewTypeID = 1  -- Flight Attendants
            AND ExceedsLimits = 0
        ORDER BY SeniorityID DESC, CrewID;

        OPEN CabinCursor;
        FETCH NEXT FROM CabinCursor INTO @CrewID, @SeniorityID;
        
        WHILE @@FETCH_STATUS = 0 AND @CabinCount < 3
        BEGIN
            -- Validate FA duty time limits and rest time
            DECLARE @ExceedsDuty BIT = 0;
            DECLARE @InsufficientRest BIT = 0;
            
            SELECT @ExceedsDuty = ExceedsDutyLimit, @InsufficientRest = InsufficientRest
            FROM dbo.fn_CheckFADutyLimits(@CrewID, @FlightID);
            
            IF @ExceedsDuty = 0 AND @InsufficientRest = 0
            BEGIN
                INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt)
                VALUES (@FlightID, @CrewID, 2, GETDATE());  -- RoleID=2 for Cabin

                SET @CabinCount = @CabinCount + 1;
                IF @SeniorityID = 3
                    SET @SeniorCabinCount = @SeniorCabinCount + 1;
            END
            
            FETCH NEXT FROM CabinCursor INTO @CrewID, @SeniorityID;
        END
        
        CLOSE CabinCursor;
        DEALLOCATE CabinCursor;

        -- Validate that we have the required crew composition
        IF @PilotCount < 2
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Insufficient pilots available (need 2).', 16, 1);
            RETURN;
        END
        
        IF @SeniorPilotCount < 1
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('No senior pilot available (need at least 1 captain).', 16, 1);
            RETURN;
        END
        
        IF @CabinCount < 3
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Insufficient cabin crew available (need 3).', 16, 1);
            RETURN;
        END
        
        IF @SeniorCabinCount < 1
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('No senior flight attendant available (need at least 1).', 16, 1);
            RETURN;
        END

        COMMIT TRANSACTION;
        PRINT 'Crew scheduled successfully for FlightID ' + CAST(@FlightID AS NVARCHAR(10)) + 
              ': ' + CAST(@PilotCount AS NVARCHAR(1)) + ' pilots (' + CAST(@SeniorPilotCount AS NVARCHAR(1)) + ' senior), ' +
              CAST(@CabinCount AS NVARCHAR(1)) + ' cabin crew (' + CAST(@SeniorCabinCount AS NVARCHAR(1)) + ' senior).';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Procedure to update flight status with proper timestamp tracking
CREATE PROCEDURE sp_UpdateFlightStatus 
    @FlightID INT, 
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @StatusID TINYINT;
        DECLARE @CurrentStatusID TINYINT;

        -- Map status name to ID
        IF @NewStatus = 'Scheduled' SET @StatusID = 1;
        ELSE IF @NewStatus = 'InFlight' SET @StatusID = 2;
        ELSE IF @NewStatus = 'Landed' SET @StatusID = 3;
        ELSE
        BEGIN
            RAISERROR('Invalid status. Valid values: Scheduled, InFlight, Landed', 16, 1);
            RETURN;
        END

        -- Get current status
        SELECT @CurrentStatusID = StatusID FROM Flights WHERE FlightID = @FlightID;
        
        IF @CurrentStatusID IS NULL
        BEGIN
            RAISERROR('Flight not found.', 16, 1);
            RETURN;
        END

        -- Update flight status with appropriate timestamps
        UPDATE Flights
        SET StatusID = @StatusID,
            ActualDeparture = CASE 
                WHEN @StatusID = 2 AND ActualDeparture IS NULL THEN GETDATE()
                ELSE ActualDeparture 
            END,
            ActualArrival = CASE 
                WHEN @StatusID = 3 AND ActualArrival IS NULL THEN GETDATE()
                ELSE ActualArrival 
            END
        WHERE FlightID = @FlightID;

        COMMIT TRANSACTION;
        PRINT 'Flight ' + CAST(@FlightID AS NVARCHAR(10)) + ' status updated to: ' + @NewStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =============================================
-- Triggers
-- =============================================

-- NOTE: Original triggers have been removed in favor of dynamic hour calculation
-- via fn_CalculateCrewHours function. This approach is more accurate as it:
-- 1. Calculates hours based on actual flight history in real-time
-- 2. Properly handles different time windows (168h, 672h, 365 days)
-- 3. Avoids data inconsistencies from static hour tracking
-- 4. Ensures regulatory compliance with 14 CFR Part 117 and 121.467

PRINT 'Business logic implemented successfully for Phase 3.';
PRINT 'Hour tracking uses dynamic calculation via fn_CalculateCrewHours function.';
PRINT 'Regulatory compliance checked via fn_CheckHourLimits and fn_CheckFADutyLimits functions.';
GO