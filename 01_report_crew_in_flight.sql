-- =============================================
-- Report 1: Crew Currently In Flight
-- =============================================
-- This report shows all crew members currently on planes in flight,
-- including their flight details and roles.
-- =============================================

SELECT
    ca.CrewID,
    c.FirstName,
    c.LastName,
    f.FlightID,
    f.FlightNumber,
    dep.City AS DepartureCity,
    dest.City AS DestinationCity,
    f.ActualDeparture AS DepartureTime,
    DATEADD(MINUTE, f.FlightDuration, f.ActualDeparture) AS ArrivalTime,
    r.RoleName AS Role,
    sl.SeniorityName AS Seniority
FROM CrewAssignments ca
JOIN Crew c ON ca.CrewID = c.CrewID
JOIN Flights f ON ca.FlightID = f.FlightID
JOIN Airports dep ON f.DepartureAirportID = dep.AirportID
JOIN Airports dest ON f.DestinationAirportID = dest.AirportID
JOIN Roles r ON ca.RoleID = r.RoleID
JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
WHERE f.StatusID = 2  -- In-flight status
ORDER BY f.FlightID, ca.RoleID DESC, c.LastName;