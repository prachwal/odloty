-- =============================================
-- Report 4: Schedule Crew for Flight
-- =============================================
-- This report suggests available crew members for scheduling
-- on a specific flight, prioritizing those with the most rest time.
-- Uses parameterized query - replace @FlightID with actual flight ID.
-- =============================================

-- Create a test scheduled flight for demonstration (FlightID = 101)
-- This flight departs in the future from NYC to Chicago
SET IDENTITY_INSERT Flights ON;
IF NOT EXISTS (SELECT 1 FROM Flights WHERE FlightID = 101)
BEGIN
    INSERT INTO Flights (FlightID, AirlineID, FlightNumber, DepartureAirportID, DestinationAirportID, FlightDuration, ScheduledDeparture, ActualDeparture, ActualArrival, IsInternational, StatusID)
    VALUES (101, 1, 'AA999', 1, 3, 120, DATEADD(DAY, 1, GETDATE()), NULL, NULL, 0, 1);
END
SET IDENTITY_INSERT Flights OFF;

DECLARE @FlightID INT = 101;  -- Use the test scheduled flight

SELECT TOP 5
    c.CrewID,
    c.FirstName + ' ' + c.LastName AS CrewName,
    a.City AS BaseCity,
    ct.CrewTypeName AS CrewType,
    sl.SeniorityName AS Seniority,
    CASE
        WHEN dbo.fn_CalculateRestTime(c.CrewID, @FlightID) >= 0
        THEN CAST(dbo.fn_CalculateRestTime(c.CrewID, @FlightID) AS VARCHAR(10)) + ' hours'
        ELSE 'No recent flight'
    END AS RestTimeStatus,
    dbo.fn_CalculateRestTime(c.CrewID, @FlightID) AS RestHours
FROM Crew c
JOIN Airports a ON c.BaseAirportID = a.AirportID
JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
JOIN CrewTypes ct ON c.CrewTypeID = ct.CrewTypeID
WHERE c.IsActive = 1
AND NOT EXISTS (
    SELECT 1
    FROM dbo.fn_CheckHourLimits(c.CrewID)
    WHERE ExceedsLimits = 1
)
AND c.BaseAirportID = (
    SELECT DepartureAirportID
    FROM Flights
    WHERE FlightID = @FlightID
)
ORDER BY dbo.fn_CalculateRestTime(c.CrewID, @FlightID) DESC;