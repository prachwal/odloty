-- =============================================
-- Script: 00_reset_crew_database.sql
-- Description: Reset CrewSchedulingDB by deleting all data
-- This script deletes all data from tables in reverse dependency order.
-- Does not drop tables or database, only clears data.
-- =============================================

USE CrewSchedulingDB;
GO

-- Delete existing data in reverse dependency order
DELETE FROM CrewAssignments;
DELETE FROM Flights;
DELETE FROM Crew;
DELETE FROM Airlines;
DELETE FROM Airports;

-- Reset IDENTITY columns
DBCC CHECKIDENT ('Airports', RESEED, 0);
DBCC CHECKIDENT ('Airlines', RESEED, 0);
DBCC CHECKIDENT ('Crew', RESEED, 0);
DBCC CHECKIDENT ('Flights', RESEED, 0);
DBCC CHECKIDENT ('CrewAssignments', RESEED, 0);
GO

PRINT 'CrewSchedulingDB data cleared successfully.';
GO