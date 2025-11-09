-- =============================================
-- Report 3: Monthly Hours Worked by Crew
-- =============================================
-- This report provides a summary of hours worked per month
-- by each crew member to support payroll processing.
-- =============================================

SELECT
    c.CrewID,
    c.FirstName,
    c.LastName,
    YEAR(f.ScheduledDeparture) AS Year,
    MONTH(f.ScheduledDeparture) AS Month,
    SUM(f.FlightDuration / 60.0) AS MonthlyHours,
    sl.SeniorityName AS Seniority
FROM CrewAssignments ca
JOIN Crew c ON ca.CrewID = c.CrewID
JOIN Flights f ON ca.FlightID = f.FlightID
JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
WHERE f.StatusID = 3  -- Completed flights
GROUP BY c.CrewID, c.FirstName, c.LastName, YEAR(f.ScheduledDeparture), MONTH(f.ScheduledDeparture), sl.SeniorityName
ORDER BY c.CrewID, Year, Month;