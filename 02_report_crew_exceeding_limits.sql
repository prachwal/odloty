-- =============================================
-- Report 2: Crew Exceeding Hour Limits
-- =============================================
-- This report lists crew members who have exceeded or are at risk
-- of exceeding their work hour limitations as per regulatory requirements.
-- Uses fn_CheckHourLimits function for accurate limit checking.
-- =============================================

SELECT
    c.CrewID,
    c.FirstName,
    c.LastName,
    HL.Hours168,
    HL.Hours672,
    HL.Hours365Days,
    HL.LimitStatus AS LimitStatus,
    sl.SeniorityName AS Seniority
FROM Crew c
CROSS APPLY dbo.fn_CheckHourLimits(c.CrewID) HL
JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
WHERE HL.ExceedsLimits = 1
ORDER BY c.CrewID;