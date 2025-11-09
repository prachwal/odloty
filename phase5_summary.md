# Phase 5 Summary: Reports from Task

## Overview

Phase 5 implements the required reports from zadanie.md: 4 SQL queries and architecture diagram description.

## Files Created

- `05_reports.sql`: Contains 4 report queries and architecture diagram

## Reports Implemented

### Report 1: Crew currently in flight

- Query: Lists crew members currently on flights with flight details
- Uses JOIN between Crew, CrewAssignments, Flights
- Filters by Status = 'InFlight'

### Report 2: Crew exceeding hour limits

- Query: Identifies crew exceeding 40-hour weekly limits
- Uses fn_CheckHourLimits function
- Returns 0 for within limits, 1 for exceeding

### Report 3: Monthly hours worked by crew

- Query: Aggregates monthly flight hours per crew
- Groups by CrewID, Year, Month
- Sums DATEDIFF hours from flight times

### Report 4: Schedule crew for a specific flight

- Demonstrates available crew for flight scheduling
- Shows crew with sufficient rest time and within limits
- Example for FlightID 92

## Architecture Diagram

- Comprehensive description of database schema
- Tables: Crew, Flights, Airlines, Airports, CrewAssignments
- Views: vw_AvailableCrew, vw_FlightCrew
- Functions: fn_CheckHourLimits, fn_CalculateRestTime
- Procedures: sp_ScheduleCrew, sp_UpdateFlightStatus
- Triggers: trg_UpdateCrewHours, trg_BeforeAssignment
- Security: SYMMETRIC KEY encryption for SSN

## Validation

- All queries execute successfully
- Architecture diagram provides complete system overview
- Reports meet zadanie.md requirements

## Next Steps

- System implementation complete
- All phases (1-5) successfully delivered
