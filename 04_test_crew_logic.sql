-- =============================================
-- Script: 04_test_crew_logic.sql
-- Description: Test business logic for CrewSchedulingDB (Phase 4)
-- This script runs unit, integration, and performance tests for SP, functions, views, and triggers.
-- Uses PRINT for results; manual verification required.
-- =============================================

USE CrewSchedulingDB;
GO

PRINT 'Starting Phase 4: Logic Tests';
GO

-- =============================================
-- Unit Tests
-- =============================================

PRINT '--- Unit Tests ---';
GO

-- Test fn_CheckHourLimits
PRINT 'Testing fn_CheckHourLimits...';
-- Note: Hours may have been updated by previous tests/triggers
DECLARE @TestCrewID INT = 1; -- John Doe, initial HoursLast168=95 (<100)
DECLARE @Result BIT = dbo.fn_CheckHourLimits(@TestCrewID);
PRINT 'CrewID 1 (John Doe): Actual: ' + CAST(@Result AS NVARCHAR(1)) + ' (May be 1 if updated by triggers)';

SET @TestCrewID = 4; -- Emily Davis, initial HoursLast168=110 (>100)
SET @Result = dbo.fn_CheckHourLimits(@TestCrewID);
PRINT 'CrewID 4 (Emily Davis): Actual: ' + CAST(@Result AS NVARCHAR(1)) + ' (Expected: 1)';

SET @TestCrewID = 21; -- Nicole Diaz, initial HoursLast7=12 (<14)
SET @Result = dbo.fn_CheckHourLimits(@TestCrewID);
PRINT 'CrewID 21 (Nicole Diaz): Actual: ' + CAST(@Result AS NVARCHAR(1)) + ' (May be 1 if updated)';
GO

-- Test fn_CalculateRestTime
PRINT 'Testing fn_CalculateRestTime...';
DECLARE @RestHours INT = dbo.fn_CalculateRestTime(1, 2); -- Assuming some assignments
PRINT 'Rest time for CrewID 1 to FlightID 2: ' + CAST(@RestHours AS NVARCHAR(10)) + ' hours (Expected: positive or -1)';
GO

-- Test vw_AvailableCrew
PRINT 'Testing vw_AvailableCrew...';
SELECT COUNT(*) AS AvailableCrewCount FROM vw_AvailableCrew;
PRINT 'Available crew count: Should be >0';
GO

-- Test vw_FlightCrew
PRINT 'Testing vw_FlightCrew...';
SELECT TOP 5 * FROM vw_FlightCrew;
PRINT 'Flight crew view: Check for assigned crew';
GO

-- Test sp_UpdateFlightStatus
PRINT 'Testing sp_UpdateFlightStatus...';
EXEC sp_UpdateFlightStatus @FlightID = 1, @NewStatus = 'InFlight';
SELECT StatusID FROM Flights WHERE FlightID = 1;
PRINT 'Flight 1 status updated to InFlight';
GO

-- Test triggers: trg_AfterAssignment (via sp_ScheduleCrew)
PRINT 'Testing trg_AfterAssignment via sp_ScheduleCrew...';
-- First, check initial hours for a crew
SELECT CrewID, HoursLast168 FROM Crew WHERE CrewID = 1;
-- Schedule crew for a flight (set flight 1 to scheduled and schedule it)
UPDATE Flights SET StatusID=1 WHERE FlightID=1;
EXEC sp_ScheduleCrew @FlightID = 1;
-- Check updated hours
SELECT CrewID, HoursLast168 FROM Crew WHERE CrewID = 1;
PRINT 'Hours updated after assignment';
GO

-- Test trg_BeforeAssignment (validation)
PRINT 'Testing trg_BeforeAssignment...';
-- Try to assign crew exceeding limits (should fail)
BEGIN TRY
    INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt) VALUES (11, 4, 1, GETDATE()); -- Emily over limit
    PRINT 'Assignment succeeded (unexpected)';
END TRY
BEGIN CATCH
    PRINT 'Assignment failed as expected: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =============================================
-- Integration Tests
-- =============================================

PRINT '--- Integration Tests ---';
GO

-- End-to-end: Schedule crew -> Update status -> Check limits
PRINT 'End-to-end test: Schedule -> Update -> Check';
EXEC sp_ScheduleCrew @FlightID = 85; -- Schedule
EXEC sp_UpdateFlightStatus @FlightID = 85, @NewStatus = 3; -- Land
SELECT dbo.fn_CheckHourLimits(CA.CrewID) FROM CrewAssignments CA WHERE CA.FlightID = 85; -- Check limits
PRINT 'End-to-end completed';
GO

-- Concurrency test: Multiple schedules (simulate with loops)
PRINT 'Concurrency test: Multiple schedules';
DECLARE @i INT = 86;
WHILE @i <= 87
BEGIN
    EXEC sp_ScheduleCrew @FlightID = @i;
    SET @i = @i + 1;
END
PRINT 'Multiple schedules completed';
GO

-- =============================================
-- Performance Tests
-- =============================================

PRINT '--- Performance Tests ---';
GO

-- Performance for sp_ScheduleCrew (simulate with existing data)
PRINT 'Performance test for sp_ScheduleCrew...';
DECLARE @StartTime DATETIME = GETDATE();
EXEC sp_ScheduleCrew @FlightID = 91; -- Use available flight
DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Duration: ' + CAST(@Duration AS NVARCHAR(10)) + ' ms (Expected: <2000 ms)';
GO

-- Performance for views with JOIN
PRINT 'Performance test for views...';
DECLARE @StartTime DATETIME = GETDATE();
SELECT COUNT(*) FROM vw_FlightCrew WHERE FlightID IN (SELECT TOP 10 FlightID FROM Flights);
DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'View query duration: ' + CAST(@Duration AS NVARCHAR(10)) + ' ms (Expected: <1000 ms)';
GO

PRINT 'Phase 4 Tests Completed. Review PRINT outputs for pass/fail.';
GO