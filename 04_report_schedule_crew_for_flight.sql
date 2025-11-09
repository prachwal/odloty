-- =============================================
-- Report 4: Schedule Crew for Flight
-- =============================================
-- This report suggests available crew members for scheduling
-- on a specific flight, prioritizing those with the most rest time.
-- Uses parameterized query - replace @FlightID with actual flight ID.
-- =============================================

DECLARE @FlightID INT = 1;  -- Replace with actual flight ID (using FlightID=1 which exists and is scheduled)

SELECT TOP 5
    c.CrewID,
    c.FirstName,
    c.LastName,
    a.City AS BaseCity,
    ct.CrewTypeName AS CrewType,
    dbo.fn_CalculateRestTime(c.CrewID, @FlightID) AS RestTimeHours,
    sl.SeniorityName AS Seniority
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
ORDER BY RestTimeHours DESC;