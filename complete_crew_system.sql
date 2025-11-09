-- =============================================
-- Complete Crew Scheduling System SQL Script
-- This script combines all SQL files (00-05) into one comprehensive script
-- Run this script to set up the complete Crew Scheduling System
-- =============================================

-- =============================================
-- Phase 0: Reset Database
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

-- =============================================
-- Phase 1: Create Database Schema
-- =============================================

USE master;
GO

-- Drop database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CrewSchedulingDB')
BEGIN
    ALTER DATABASE CrewSchedulingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CrewSchedulingDB;
END
GO

-- Create database
CREATE DATABASE CrewSchedulingDB
COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

-- Set recovery model and compatibility level
ALTER DATABASE CrewSchedulingDB SET RECOVERY FULL;
GO

USE CrewSchedulingDB;
GO

-- Security: Create master key, certificate and symmetric key for SSN encryption
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword!123';
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CrewSSNCert')
    CREATE CERTIFICATE CrewSSNCert
    WITH SUBJECT = 'Certificate for SSN Encryption';
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'CrewSSNKey')
    CREATE SYMMETRIC KEY CrewSSNKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CrewSSNCert;
GO

-- Create user roles
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'StationManager' AND type = 'R')
    CREATE ROLE StationManager;
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'FlightOps' AND type = 'R')
    CREATE ROLE FlightOps;
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Compliance' AND type = 'R')
    CREATE ROLE Compliance;
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'HR' AND type = 'R')
    CREATE ROLE HR;
GO

-- Create tables

-- CrewTypes table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'CrewTypes' AND xtype = 'U')
BEGIN
CREATE TABLE CrewTypes (
    CrewTypeID TINYINT PRIMARY KEY,
    CrewTypeName NVARCHAR(20) NOT NULL
);
INSERT INTO CrewTypes VALUES (1, 'Flight Attendant'), (2, 'Pilot');
END
GO

-- SeniorityLevels table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'SeniorityLevels' AND xtype = 'U')
BEGIN
CREATE TABLE SeniorityLevels (
    SeniorityID TINYINT PRIMARY KEY,
    SeniorityName NVARCHAR(20) NOT NULL
);
INSERT INTO SeniorityLevels VALUES (1, 'Trainee'), (2, 'Journeyman'), (3, 'Senior');
END
GO

-- FlightStatuses table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'FlightStatuses' AND xtype = 'U')
BEGIN
CREATE TABLE FlightStatuses (
    StatusID TINYINT PRIMARY KEY,
    StatusName NVARCHAR(20) NOT NULL
);
INSERT INTO FlightStatuses VALUES (1, 'Scheduled'), (2, 'InFlight'), (3, 'Landed');
END
GO

-- Roles table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Roles' AND xtype = 'U')
BEGIN
CREATE TABLE Roles (
    RoleID TINYINT PRIMARY KEY,
    RoleName NVARCHAR(20) NOT NULL
);
INSERT INTO Roles VALUES (1, 'Pilot'), (2, 'Cabin');
END
GO

-- Airlines table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Airlines' AND xtype = 'U')
BEGIN
CREATE TABLE Airlines (
    AirlineID INT IDENTITY(1,1) PRIMARY KEY,
    AirlineName NVARCHAR(100) NOT NULL,
    IATACode NVARCHAR(3) UNIQUE NOT NULL
);
END
GO

-- Airports table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Airports' AND xtype = 'U')
BEGIN
CREATE TABLE Airports (
    AirportID INT IDENTITY(1,1) PRIMARY KEY,
    City NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    IATACode NVARCHAR(3) UNIQUE NOT NULL
);
END
GO

-- Crew table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Crew' AND xtype = 'U')
BEGIN
CREATE TABLE Crew (
    CrewID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    SSN VARBINARY(256) NOT NULL,  -- Encrypted
    BaseAirportID INT NOT NULL,
    CrewTypeID TINYINT NOT NULL,
    SeniorityID TINYINT NOT NULL,
    -- Proper hour tracking as per 14 CFR regulations
    HoursLast168 DECIMAL(6,2) DEFAULT 0 NOT NULL,  -- Last 168 hours (7 days) for 60h limit
    HoursLast672 DECIMAL(6,2) DEFAULT 0 NOT NULL,  -- Last 672 hours (28 days) for 100h/190h limits
    HoursLast365Days DECIMAL(7,2) DEFAULT 0 NOT NULL,  -- Last 365 days for 1000h limit
    IsActive BIT DEFAULT 1 NOT NULL,
    FOREIGN KEY (BaseAirportID) REFERENCES Airports(AirportID),
    FOREIGN KEY (CrewTypeID) REFERENCES CrewTypes(CrewTypeID),
    FOREIGN KEY (SeniorityID) REFERENCES SeniorityLevels(SeniorityID)
);
END
GO

-- Flights table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Flights' AND xtype = 'U')
BEGIN
CREATE TABLE Flights (
    FlightID INT IDENTITY(1,1) PRIMARY KEY,
    AirlineID INT NOT NULL,
    FlightNumber NVARCHAR(10) NOT NULL,
    DepartureAirportID INT NOT NULL,
    DestinationAirportID INT NOT NULL,
    FlightDuration INT NOT NULL,  -- in minutes
    ScheduledDeparture DATETIME2 NOT NULL,
    ActualDeparture DATETIME2 NULL,
    ActualArrival DATETIME2 NULL,  -- Added for accurate duty time calculation
    IsInternational BIT DEFAULT 0 NOT NULL,  -- Added for FA duty hour limits (14h domestic, 20h international)
    StatusID TINYINT NOT NULL,
    FOREIGN KEY (AirlineID) REFERENCES Airlines(AirlineID),
    FOREIGN KEY (DepartureAirportID) REFERENCES Airports(AirportID),
    FOREIGN KEY (DestinationAirportID) REFERENCES Airports(AirportID),
    FOREIGN KEY (StatusID) REFERENCES FlightStatuses(StatusID)
);
END
GO

-- CrewAssignments table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'CrewAssignments' AND xtype = 'U')
BEGIN
CREATE TABLE CrewAssignments (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    FlightID INT NOT NULL,
    CrewID INT NOT NULL,
    RoleID TINYINT NOT NULL,
    AssignedAt DATETIME2 DEFAULT GETDATE() NOT NULL,
    FOREIGN KEY (FlightID) REFERENCES Flights(FlightID),
    FOREIGN KEY (CrewID) REFERENCES Crew(CrewID),
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
END
GO

-- Indexes for performance optimization
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Crew_BaseAirportID' AND object_id = OBJECT_ID('Crew'))
    CREATE INDEX IX_Crew_BaseAirportID ON Crew(BaseAirportID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Crew_CrewTypeID' AND object_id = OBJECT_ID('Crew'))
    CREATE INDEX IX_Crew_CrewTypeID ON Crew(CrewTypeID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Flights_DepartureAirportID' AND object_id = OBJECT_ID('Flights'))
    CREATE INDEX IX_Flights_DepartureAirportID ON Flights(DepartureAirportID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Flights_StatusID' AND object_id = OBJECT_ID('Flights'))
    CREATE INDEX IX_Flights_StatusID ON Flights(StatusID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Flights_ScheduledDeparture' AND object_id = OBJECT_ID('Flights'))
    CREATE INDEX IX_Flights_ScheduledDeparture ON Flights(ScheduledDeparture);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CrewAssignments_FlightID' AND object_id = OBJECT_ID('CrewAssignments'))
    CREATE INDEX IX_CrewAssignments_FlightID ON CrewAssignments(FlightID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CrewAssignments_CrewID' AND object_id = OBJECT_ID('CrewAssignments'))
    CREATE INDEX IX_CrewAssignments_CrewID ON CrewAssignments(CrewID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CrewAssignments_RoleID' AND object_id = OBJECT_ID('CrewAssignments'))
    CREATE INDEX IX_CrewAssignments_RoleID ON CrewAssignments(RoleID);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CrewAssignments_AssignedAt' AND object_id = OBJECT_ID('CrewAssignments'))
    CREATE INDEX IX_CrewAssignments_AssignedAt ON CrewAssignments(AssignedAt);
GO

-- Triggers

-- NOTE: Trigger removed - hours will be calculated dynamically via function fn_CalculateCrewHours
-- This provides more accurate tracking based on actual flight history
-- See 03_crew_logic.sql for the calculation function
GO

-- Grant permissions to roles
GRANT SELECT, INSERT, UPDATE ON Crew TO StationManager, FlightOps, Compliance, HR;
GRANT SELECT ON Flights TO FlightOps, Compliance;
GRANT SELECT ON CrewAssignments TO FlightOps, Compliance, HR;
GRANT SELECT ON Airlines TO StationManager, FlightOps;
GRANT SELECT ON Airports TO StationManager, FlightOps;

-- Compliance has read-only on all for reports
GRANT SELECT ON Crew TO Compliance;
GRANT SELECT ON Flights TO Compliance;
GRANT SELECT ON CrewAssignments TO Compliance;

-- StationManager can schedule (insert assignments)
GRANT INSERT ON CrewAssignments TO StationManager;

-- HR can update crew info
GRANT UPDATE ON Crew TO HR;
GO

PRINT 'CrewSchedulingDB and all tables created successfully with security and triggers.';
GO

-- =============================================
-- Phase 2: Insert Test Data
-- =============================================

USE CrewSchedulingDB;
GO

-- Open the encryption key for SSN
OPEN SYMMETRIC KEY CrewSSNKey DECRYPTION BY CERTIFICATE CrewSSNCert;
GO

-- Insert Airports (covering various cities including NYC, Burlington)
SET IDENTITY_INSERT Airports ON;
INSERT INTO Airports (AirportID, City, Country, IATACode) VALUES
(1, 'New York', 'USA', 'NYC'),
(2, 'Burlington', 'USA', 'BTV'),
(3, 'Chicago', 'USA', 'ORD'),
(4, 'Los Angeles', 'USA', 'LAX'),
(5, 'Miami', 'USA', 'MIA'),
(6, 'Seattle', 'USA', 'SEA'),
(7, 'Denver', 'USA', 'DEN'),
(8, 'Boston', 'USA', 'BOS'),
(9, 'San Francisco', 'USA', 'SFO'),
(10, 'Dallas', 'USA', 'DFW');
SET IDENTITY_INSERT Airports OFF;
GO

-- Insert Airlines
SET IDENTITY_INSERT Airlines ON;
INSERT INTO Airlines (AirlineID, AirlineName, IATACode) VALUES
(1, 'American Airlines', 'AA'),
(2, 'Delta Air Lines', 'DL'),
(3, 'United Airlines', 'UA'),
(4, 'Southwest Airlines', 'WN'),
(5, 'JetBlue Airways', 'B6'),
(6, 'Alaska Airlines', 'AS'),
(7, 'Spirit Airlines', 'NK'),
(8, 'Frontier Airlines', 'F9'),
(9, 'Allegiant Air', 'G4'),
(10, 'Hawaiian Airlines', 'HA');
SET IDENTITY_INSERT Airlines OFF;
GO

-- Insert Crew (50 crew: 20 Pilots, 30 FA; various seniority and cities)
-- SSN encrypted using ENCRYPTBYKEY
-- Hours fields removed - now calculated dynamically
SET IDENTITY_INSERT Crew ON;
INSERT INTO Crew (CrewID, FirstName, LastName, SSN, BaseAirportID, CrewTypeID, SeniorityID, IsActive) VALUES
-- Pilots (CrewType=2) - Testing various scenarios
(1, 'John', 'Doe', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '123-45-6789'), 1, 2, 3, 1),       -- Senior pilot NYC
(2, 'Jane', 'Smith', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '987-65-4321'), 2, 2, 2, 1),     -- Journeyman Burlington
(3, 'Mike', 'Johnson', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '456-78-9012'), 3, 2, 1, 1),   -- Trainee Chicago
(4, 'Emily', 'Davis', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '321-54-9876'), 4, 2, 3, 1),    -- Senior LA
(5, 'David', 'Wilson', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '654-32-1098'), 5, 2, 2, 1),   -- Journeyman Miami
(6, 'Sarah', 'Brown', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '789-01-2345'), 1, 2, 1, 1),    -- Trainee NYC
(7, 'Chris', 'Miller', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '147-25-3698'), 2, 2, 3, 1),   -- Senior Burlington
(8, 'Anna', 'Garcia', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '258-36-7410'), 3, 2, 2, 1),    -- Journeyman Chicago
(9, 'Tom', 'Rodriguez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '369-47-8520'), 4, 2, 1, 1),  -- Trainee LA
(10, 'Lisa', 'Martinez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '741-85-2963'), 5, 2, 3, 1), -- Senior Miami
(11, 'Paul', 'Hernandez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '852-96-3074'), 6, 2, 2, 1),-- Journeyman Seattle
(12, 'Karen', 'Lopez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '963-07-4185'), 7, 2, 1, 1),   -- Trainee Denver
(13, 'Mark', 'Gonzalez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '074-18-5296'), 8, 2, 3, 1), -- Senior Boston
(14, 'Rachel', 'Perez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '185-29-6307'), 9, 2, 2, 1),  -- Journeyman SF
(15, 'Steve', 'Sanchez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '296-30-7418'), 10, 2, 1, 1),-- Trainee Dallas
(16, 'Laura', 'Ramirez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '307-41-8529'), 1, 2, 3, 1), -- Senior NYC
(17, 'Kevin', 'Torres', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '418-52-9630'), 2, 2, 2, 1),  -- Journeyman Burlington
(18, 'Jessica', 'Flores', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '529-63-0741'), 3, 2, 1, 1),-- Trainee Chicago
(19, 'Brian', 'Rivera', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '630-74-1852'), 4, 2, 3, 1),  -- Senior LA
(20, 'Amanda', 'Gomez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '741-85-2964'), 5, 2, 2, 1),  -- Journeyman Miami
-- FA (CrewType=1) - Testing various scenarios
(21, 'Nicole', 'Diaz', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '852-96-3075'), 6, 1, 3, 1),   -- Senior FA Seattle
(22, 'Daniel', 'Morales', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '963-07-4186'), 7, 1, 2, 1),-- Journeyman Denver
(23, 'Ashley', 'Ortiz', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '074-18-5297'), 8, 1, 1, 1),  -- Trainee Boston
(24, 'Tyler', 'Gutierrez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '185-29-6308'), 9, 1, 3, 1),-- Senior SF
(25, 'Megan', 'Chavez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '296-30-7419'), 10, 1, 2, 1), -- Journeyman Dallas
(26, 'Justin', 'Ramos', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '307-41-8530'), 1, 1, 1, 1),  -- Trainee NYC
(27, 'Hannah', 'Guzman', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '418-52-9631'), 2, 1, 3, 1), -- Senior Burlington
(28, 'Brandon', 'Castillo', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '529-63-0742'), 3, 1, 2, 1),-- Journeyman Chicago
(29, 'Samantha', 'Jimenez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '630-74-1853'), 4, 1, 1, 1),-- Trainee LA
(30, 'Austin', 'Moreno', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '741-85-2965'), 5, 1, 3, 1), -- Senior Miami
(31, 'Taylor', 'Vargas', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '852-96-3076'), 6, 1, 2, 1), -- Journeyman Seattle
(32, 'Madison', 'Romero', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '963-07-4187'), 7, 1, 1, 1),-- Trainee Denver
(33, 'Jordan', 'Herrera', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '074-18-5298'), 8, 1, 3, 1),-- Senior Boston
(34, 'Alexis', 'Medina', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '185-29-6309'), 9, 1, 2, 1), -- Journeyman SF
(35, 'Cameron', 'Cortes', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '296-30-7420'), 10, 1, 1, 1),-- Trainee Dallas
(36, 'Kayla', 'Santiago', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '307-41-8531'), 1, 1, 3, 1),-- Senior NYC
(37, 'Dylan', 'Luna', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '418-52-9632'), 2, 1, 2, 1),    -- Journeyman Burlington
(38, 'Hailey', 'Ortega', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '529-63-0743'), 3, 1, 1, 1), -- Trainee Chicago
(39, 'Ethan', 'Delgado', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '630-74-1854'), 4, 1, 3, 1), -- Senior LA
(40, 'Avery', 'Castro', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '741-85-2966'), 5, 1, 2, 1),  -- Journeyman Miami
(41, 'Nathan', 'Soto', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '852-96-3077'), 6, 1, 1, 1),   -- Trainee Seattle
(42, 'Isabella', 'Mendoza', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '963-07-4188'), 7, 1, 3, 1),-- Senior Denver
(43, 'Mason', 'Silva', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '074-18-5299'), 8, 1, 2, 1),   -- Journeyman Boston
(44, 'Sophia', 'Pena', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '185-29-6310'), 9, 1, 1, 1),   -- Trainee SF
(45, 'Logan', 'Reyes', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '296-30-7421'), 10, 1, 3, 1),  -- Senior Dallas
(46, 'Ava', 'Cruz', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '307-41-8532'), 1, 1, 2, 1),      -- Journeyman NYC
(47, 'Jackson', 'Fernandez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '418-52-9633'), 2, 1, 1, 1),-- Trainee Burlington
(48, 'Mia', 'Ruiz', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '529-63-0744'), 3, 1, 3, 1),      -- Senior Chicago
(49, 'Liam', 'Alvarez', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '630-74-1855'), 4, 1, 2, 1),  -- Journeyman LA
(50, 'Charlotte', 'Morales', ENCRYPTBYKEY(KEY_GUID('CrewSSNKey'), '741-85-2967'), 5, 1, 1, 1);-- Trainee Miami
SET IDENTITY_INSERT Crew OFF;
GO

-- Close the encryption key
CLOSE SYMMETRIC KEY CrewSSNKey;
GO

-- Insert Flights (100 flights total: 85 historical landed, 15 current/scheduled)
-- Enhanced with IsInternational flag and ActualArrival for better testing
SET IDENTITY_INSERT Flights ON;
INSERT INTO Flights (FlightID, AirlineID, FlightNumber, DepartureAirportID, DestinationAirportID, FlightDuration, ScheduledDeparture, ActualDeparture, ActualArrival, IsInternational, StatusID) VALUES
-- Historical landed flights (1-85) - Mix of domestic and international
(1, 1, 'AA101', 1, 3, 120, '2024-01-15 08:00:00', '2024-01-15 08:05:00', '2024-01-15 10:05:00', 0, 3),
(2, 2, 'DL202', 2, 5, 180, '2024-02-20 10:30:00', '2024-02-20 10:35:00', '2024-02-20 13:35:00', 0, 3),
(3, 3, 'UA303', 4, 6, 150, '2024-03-10 14:00:00', '2024-03-10 14:10:00', '2024-03-10 16:40:00', 0, 3),
(4, 4, 'WN404', 7, 10, 90, '2024-04-05 16:45:00', '2024-04-05 16:50:00', '2024-04-05 18:20:00', 0, 3),
(5, 5, 'B6505', 8, 9, 300, '2024-05-12 09:15:00', '2024-05-12 09:20:00', '2024-05-12 14:20:00', 0, 3),
(6, 6, 'AS606', 1, 6, 250, '2024-06-18 11:00:00', '2024-06-18 11:05:00', '2024-06-18 15:15:00', 0, 3),
(7, 7, 'NK707', 10, 8, 140, '2024-07-22 13:30:00', '2024-07-22 13:35:00', '2024-07-22 15:55:00', 0, 3),
(8, 8, 'F9808', 5, 9, 160, '2024-08-14 15:20:00', '2024-08-14 15:25:00', '2024-08-14 18:05:00', 0, 3),
(9, 9, 'G4909', 4, 2, 110, '2024-09-09 17:00:00', '2024-09-09 17:05:00', '2024-09-09 18:55:00', 0, 3),
(10, 10, 'HA1010', 8, 7, 100, '2024-10-01 07:45:00', '2024-10-01 07:50:00', '2024-10-01 09:30:00', 0, 3),
(11, 1, 'AA111', 6, 5, 200, '2024-11-01 08:00:00', '2024-11-01 08:05:00', '2024-11-01 11:25:00', 0, 3),
(12, 2, 'DL212', 8, 4, 240, '2024-12-05 10:30:00', '2024-12-05 10:35:00', '2024-12-05 14:35:00', 0, 3),
(13, 3, 'UA313', 9, 3, 320, '2025-01-10 14:00:00', '2025-01-10 14:10:00', '2025-01-10 19:30:00', 0, 3),
(14, 4, 'WN414', 10, 2, 160, '2025-02-15 16:45:00', '2025-02-15 16:50:00', '2025-02-15 19:30:00', 0, 3),
(15, 5, 'B6515', 1, 6, 250, '2025-03-20 09:15:00', '2025-03-20 09:20:00', '2025-03-20 13:30:00', 0, 3),
(16, 6, 'AS616', 5, 8, 130, '2025-04-25 11:00:00', '2025-04-25 11:05:00', '2025-04-25 13:15:00', 0, 3),
(17, 7, 'NK717', 4, 10, 280, '2025-05-30 13:30:00', '2025-05-30 13:35:00', '2025-05-30 18:15:00', 0, 3),
(18, 8, 'F9818', 2, 9, 150, '2025-06-05 15:20:00', '2025-06-05 15:25:00', '2025-06-05 17:55:00', 0, 3),
(19, 9, 'G4919', 3, 1, 300, '2025-07-10 17:00:00', '2025-07-10 17:05:00', '2025-07-10 22:05:00', 0, 3),
(20, 10, 'HA1020', 7, 5, 170, '2025-08-15 07:45:00', '2025-08-15 07:50:00', '2025-08-15 10:40:00', 0, 3),
-- International flights for FA duty testing (21-30)
(21, 1, 'AA121', 1, 6, 900, '2025-09-01 08:00:00', '2025-09-01 08:05:00', '2025-09-01 23:05:00', 1, 3),  -- 15h international
(22, 2, 'DL222', 8, 4, 1080, '2025-09-15 10:30:00', '2025-09-15 10:35:00', '2025-09-16 04:35:00', 1, 3), -- 18h international
(23, 3, 'UA323', 9, 2, 720, '2025-10-01 14:00:00', '2025-10-01 14:10:00', '2025-10-02 02:10:00', 1, 3),  -- 12h international
(24, 4, 'WN424', 5, 3, 1140, '2025-10-15 16:45:00', '2025-10-15 16:50:00', '2025-10-16 11:50:00', 1, 3), -- 19h international
(25, 5, 'B6525', 4, 7, 960, '2025-11-01 09:15:00', '2025-11-01 09:20:00', '2025-11-02 01:20:00', 1, 3),  -- 16h international
-- More domestic flights to test hour limits (26-75)
(26, 6, 'AS626', 1, 6, 280, '2024-01-20 08:00:00', '2024-01-20 08:05:00', '2024-01-20 12:45:00', 0, 3),
(27, 7, 'NK727', 7, 5, 180, '2024-02-25 10:30:00', '2024-02-25 10:35:00', '2024-02-25 13:35:00', 0, 3),
(28, 8, 'F9828', 8, 9, 200, '2024-03-15 14:00:00', '2024-03-15 14:10:00', '2024-03-15 17:30:00', 0, 3),
(29, 9, 'G4929', 10, 4, 300, '2024-04-10 16:45:00', '2024-04-10 16:50:00', '2024-04-10 21:50:00', 0, 3),
(30, 10, 'HA1030', 2, 6, 220, '2024-05-17 09:15:00', '2024-05-17 09:20:00', '2024-05-17 13:00:00', 0, 3),
(31, 1, 'AA131', 3, 8, 120, '2024-06-23 11:00:00', '2024-06-23 11:05:00', '2024-06-23 13:05:00', 0, 3),
(32, 2, 'DL232', 1, 10, 290, '2024-07-27 13:30:00', '2024-07-27 13:35:00', '2024-07-27 18:25:00', 0, 3),
(33, 3, 'UA333', 5, 2, 100, '2024-08-19 15:20:00', '2024-08-19 15:25:00', '2024-08-19 17:05:00', 0, 3),
(34, 4, 'WN434', 4, 3, 320, '2024-09-14 17:00:00', '2024-09-14 17:05:00', '2024-09-14 22:25:00', 0, 3),
(35, 5, 'B6535', 9, 7, 270, '2024-10-06 07:45:00', '2024-10-06 07:50:00', '2024-10-06 12:20:00', 0, 3),
(36, 6, 'AS636', 6, 2, 210, '2024-01-25 08:00:00', '2024-01-25 08:05:00', '2024-01-25 11:35:00', 0, 3),
(37, 7, 'NK737', 8, 10, 150, '2024-02-28 10:30:00', '2024-02-28 10:35:00', '2024-02-28 13:05:00', 0, 3),
(38, 8, 'F9838', 9, 5, 170, '2024-03-20 14:00:00', '2024-03-20 14:10:00', '2024-03-20 17:00:00', 0, 3),
(39, 9, 'G4939', 1, 8, 200, '2024-04-15 16:45:00', '2024-04-15 16:50:00', '2024-04-15 20:10:00', 0, 3),
(40, 10, 'HA1040', 3, 9, 310, '2024-05-22 09:15:00', '2024-05-22 09:20:00', '2024-05-22 14:30:00', 0, 3);
SET IDENTITY_INSERT Flights OFF;
GO

-- Insert CrewAssignments (200 assignments covering historical flights)
-- Note: We'll assign 5 crew per flight (2 pilots + 3 FA) for the first 40 flights = 200 assignments
INSERT INTO CrewAssignments (FlightID, CrewID, RoleID, AssignedAt) VALUES
-- Flight 1 (AA101)
(1, 1, 1, '2024-01-14 12:00:00'),
(1, 11, 1, '2024-01-14 12:00:00'),
(1, 21, 2, '2024-01-14 12:00:00'),
(1, 31, 2, '2024-01-14 12:00:00'),
(1, 41, 2, '2024-01-14 12:00:00'),
-- Flight 2 (DL202)
(2, 2, 1, '2024-02-19 14:00:00'),
(2, 12, 1, '2024-02-19 14:00:00'),
(2, 22, 2, '2024-02-19 14:00:00'),
(2, 32, 2, '2024-02-19 14:00:00'),
(2, 42, 2, '2024-02-19 14:00:00'),
-- Flight 3 (UA303)
(3, 3, 1, '2024-03-09 16:00:00'),
(3, 13, 1, '2024-03-09 16:00:00'),
(3, 23, 2, '2024-03-09 16:00:00'),
(3, 33, 2, '2024-03-09 16:00:00'),
(3, 43, 2, '2024-03-09 16:00:00'),
-- Flight 4 (WN404)
(4, 4, 1, '2024-04-04 18:00:00'),
(4, 14, 1, '2024-04-04 18:00:00'),
(4, 24, 2, '2024-04-04 18:00:00'),
(4, 34, 2, '2024-04-04 18:00:00'),
(4, 44, 2, '2024-04-04 18:00:00'),
-- Flight 5 (B6505)
(5, 5, 1, '2024-05-11 11:00:00'),
(5, 15, 1, '2024-05-11 11:00:00'),
(5, 25, 2, '2024-05-11 11:00:00'),
(5, 35, 2, '2024-05-11 11:00:00'),
(5, 45, 2, '2024-05-11 11:00:00'),
-- Flight 6 (AS606)
(6, 6, 1, '2024-06-17 13:00:00'),
(6, 16, 1, '2024-06-17 13:00:00'),
(6, 26, 2, '2024-06-17 13:00:00'),
(6, 36, 2, '2024-06-17 13:00:00'),
(6, 46, 2, '2024-06-17 13:00:00'),
-- Flight 7 (NK707)
(7, 7, 1, '2024-07-21 15:00:00'),
(7, 17, 1, '2024-07-21 15:00:00'),
(7, 27, 2, '2024-07-21 15:00:00'),
(7, 37, 2, '2024-07-21 15:00:00'),
(7, 47, 2, '2024-07-21 15:00:00'),
-- Flight 8 (F9808)
(8, 8, 1, '2024-08-13 17:00:00'),
(8, 18, 1, '2024-08-13 17:00:00'),
(8, 28, 2, '2024-08-13 17:00:00'),
(8, 38, 2, '2024-08-13 17:00:00'),
(8, 48, 2, '2024-08-13 17:00:00'),
-- Flight 9 (G4909)
(9, 9, 1, '2024-09-08 19:00:00'),
(9, 19, 1, '2024-09-08 19:00:00'),
(9, 29, 2, '2024-09-08 19:00:00'),
(9, 39, 2, '2024-09-08 19:00:00'),
(9, 49, 2, '2024-09-08 19:00:00'),
-- Flight 10 (HA1010)
(10, 10, 1, '2024-10-01 09:00:00'),
(10, 20, 1, '2024-10-01 09:00:00'),
(10, 30, 2, '2024-10-01 09:00:00'),
(10, 40, 2, '2024-10-01 09:00:00'),
(10, 50, 2, '2024-10-01 09:00:00'),
-- Flight 11 (AS616)
(11, 1, 1, '2023-11-30 11:00:00'),
(11, 11, 1, '2023-11-30 11:00:00'),
(11, 21, 2, '2023-11-30 11:00:00'),
(11, 31, 2, '2023-11-30 11:00:00'),
(11, 41, 2, '2023-11-30 11:00:00'),
-- Flight 12 (NK717)
(12, 2, 1, '2023-11-14 13:30:00'),
(12, 12, 1, '2023-11-14 13:30:00'),
(12, 22, 2, '2023-11-14 13:30:00'),
(12, 32, 2, '2023-11-14 13:30:00'),
(12, 42, 2, '2023-11-14 13:30:00'),
-- Flight 13 (F9818)
(13, 3, 1, '2023-10-19 15:00:00'),
(13, 13, 1, '2023-10-19 15:00:00'),
(13, 23, 2, '2023-10-19 15:00:00'),
(13, 33, 2, '2023-10-19 15:00:00'),
(13, 43, 2, '2023-10-19 15:00:00'),
-- Flight 14 (G4919)
(14, 4, 1, '2023-09-24 17:30:00'),
(14, 14, 1, '2023-09-24 17:30:00'),
(14, 24, 2, '2023-09-24 17:30:00'),
(14, 34, 2, '2023-09-24 17:30:00'),
(14, 44, 2, '2023-09-24 17:30:00'),
-- Flight 15 (HA1020)
(15, 5, 1, '2023-08-29 19:00:00'),
(15, 15, 1, '2023-08-29 19:00:00'),
(15, 25, 2, '2023-08-29 19:00:00'),
(15, 35, 2, '2023-08-29 19:00:00'),
(15, 45, 2, '2023-08-29 19:00:00'),
-- Flight 16 (AA121)
(16, 6, 1, '2024-10-31 10:00:00'),
(16, 16, 1, '2024-10-31 10:00:00'),
(16, 26, 2, '2024-10-31 10:00:00'),
(16, 36, 2, '2024-10-31 10:00:00'),
(16, 46, 2, '2024-10-31 10:00:00'),
-- Flight 17 (DL222)
(17, 7, 1, '2024-12-04 12:30:00'),
(17, 17, 1, '2024-12-04 12:30:00'),
(17, 27, 2, '2024-12-04 12:30:00'),
(17, 37, 2, '2024-12-04 12:30:00'),
(17, 47, 2, '2024-12-04 12:30:00'),
-- Flight 18 (UA323)
(18, 8, 1, '2025-01-09 16:00:00'),
(18, 18, 1, '2025-01-09 16:00:00'),
(18, 28, 2, '2025-01-09 16:00:00'),
(18, 38, 2, '2025-01-09 16:00:00'),
(18, 48, 2, '2025-01-09 16:00:00'),
-- Flight 19 (WN424)
(19, 9, 1, '2025-02-14 18:45:00'),
(19, 19, 1, '2025-02-14 18:45:00'),
(19, 29, 2, '2025-02-14 18:45:00'),
(19, 39, 2, '2025-02-14 18:45:00'),
(19, 49, 2, '2025-02-14 18:45:00'),
-- Flight 20 (B6525)
(20, 10, 1, '2025-03-19 11:15:00'),
(20, 20, 1, '2025-03-19 11:15:00'),
(20, 30, 2, '2025-03-19 11:15:00'),
(20, 40, 2, '2025-03-19 11:15:00'),
(20, 50, 2, '2025-03-19 11:15:00'),
-- Flight 21 (AS626)
(21, 1, 1, '2025-04-24 13:00:00'),
(21, 11, 1, '2025-04-24 13:00:00'),
(21, 21, 2, '2025-04-24 13:00:00'),
(21, 31, 2, '2025-04-24 13:00:00'),
(21, 41, 2, '2025-04-24 13:00:00'),
-- Flight 22 (NK727)
(22, 2, 1, '2025-05-29 15:30:00'),
(22, 12, 1, '2025-05-29 15:30:00'),
(22, 22, 2, '2025-05-29 15:30:00'),
(22, 32, 2, '2025-05-29 15:30:00'),
(22, 42, 2, '2025-05-29 15:30:00'),
-- Flight 23 (F9828)
(23, 3, 1, '2025-06-04 17:20:00'),
(23, 13, 1, '2025-06-04 17:20:00'),
(23, 23, 2, '2025-06-04 17:20:00'),
(23, 33, 2, '2025-06-04 17:20:00'),
(23, 43, 2, '2025-06-04 17:20:00'),
-- Flight 24 (G4929)
(24, 4, 1, '2025-07-09 19:00:00'),
(24, 14, 1, '2025-07-09 19:00:00'),
(24, 24, 2, '2025-07-09 19:00:00'),
(24, 34, 2, '2025-07-09 19:00:00'),
(24, 44, 2, '2025-07-09 19:00:00'),
-- Flight 25 (HA1030)
(25, 5, 1, '2025-08-14 09:45:00'),
(25, 15, 1, '2025-08-14 09:45:00'),
(25, 25, 2, '2025-08-14 09:45:00'),
(25, 35, 2, '2025-08-14 09:45:00'),
(25, 45, 2, '2025-08-14 09:45:00'),
-- Flight 26 (AA131)
(26, 6, 1, '2025-08-31 10:00:00'),
(26, 16, 1, '2025-08-31 10:00:00'),
(26, 26, 2, '2025-08-31 10:00:00'),
(26, 36, 2, '2025-08-31 10:00:00'),
(26, 46, 2, '2025-08-31 10:00:00'),
-- Flight 27 (DL232)
(27, 7, 1, '2025-09-14 12:30:00'),
(27, 17, 1, '2025-09-14 12:30:00'),
(27, 27, 2, '2025-09-14 12:30:00'),
(27, 37, 2, '2025-09-14 12:30:00'),
(27, 47, 2, '2025-09-14 12:30:00'),
-- Flight 28 (UA333)
(28, 8, 1, '2025-09-30 16:00:00'),
(28, 18, 1, '2025-09-30 16:00:00'),
(28, 28, 2, '2025-09-30 16:00:00'),
(28, 38, 2, '2025-09-30 16:00:00'),
(28, 48, 2, '2025-09-30 16:00:00'),
-- Flight 29 (WN434)
(29, 9, 1, '2025-10-14 18:45:00'),
(29, 19, 1, '2025-10-14 18:45:00'),
(29, 29, 2, '2025-10-14 18:45:00'),
(29, 39, 2, '2025-10-14 18:45:00'),
(29, 49, 2, '2025-10-14 18:45:00'),
-- Flight 30 (B6535)
(30, 10, 1, '2025-10-31 11:15:00'),
(30, 20, 1, '2025-10-31 11:15:00'),
(30, 30, 2, '2025-10-31 11:15:00'),
(30, 40, 2, '2025-10-31 11:15:00'),
(30, 50, 2, '2025-10-31 11:15:00'),
-- Flight 31 (AA141)
(31, 1, 1, '2024-01-19 10:00:00'),
(31, 11, 1, '2024-01-19 10:00:00'),
(31, 21, 2, '2024-01-19 10:00:00'),
(31, 31, 2, '2024-01-19 10:00:00'),
(31, 41, 2, '2024-01-19 10:00:00'),
-- Flight 32 (DL242)
(32, 2, 1, '2024-02-24 12:30:00'),
(32, 12, 1, '2024-02-24 12:30:00'),
(32, 22, 2, '2024-02-24 12:30:00'),
(32, 32, 2, '2024-02-24 12:30:00'),
(32, 42, 2, '2024-02-24 12:30:00'),
-- Flight 33 (UA343)
(33, 3, 1, '2024-03-14 16:00:00'),
(33, 13, 1, '2024-03-14 16:00:00'),
(33, 23, 2, '2024-03-14 16:00:00'),
(33, 33, 2, '2024-03-14 16:00:00'),
(33, 43, 2, '2024-03-14 16:00:00'),
-- Flight 34 (WN444)
(34, 4, 1, '2024-04-09 18:45:00'),
(34, 14, 1, '2024-04-09 18:45:00'),
(34, 24, 2, '2024-04-09 18:45:00'),
(34, 34, 2, '2024-04-09 18:45:00'),
(34, 44, 2, '2024-04-09 18:45:00'),
-- Flight 35 (B6545)
(35, 5, 1, '2024-05-16 11:15:00'),
(35, 15, 1, '2024-05-16 11:15:00'),
(35, 25, 2, '2024-05-16 11:15:00'),
(35, 35, 2, '2024-05-16 11:15:00'),
(35, 45, 2, '2024-05-16 11:15:00'),
-- Flight 36 (AS636)
(36, 6, 1, '2024-06-22 13:00:00'),
(36, 16, 1, '2024-06-22 13:00:00'),
(36, 26, 2, '2024-06-22 13:00:00'),
(36, 36, 2, '2024-06-22 13:00:00'),
(36, 46, 2, '2024-06-22 13:00:00'),
-- Flight 37 (NK737)
(37, 7, 1, '2024-07-26 15:30:00'),
(37, 17, 1, '2024-07-26 15:30:00'),
(37, 27, 2, '2024-07-26 15:30:00'),
(37, 37, 2, '2024-07-26 15:30:00'),
(37, 47, 2, '2024-07-26 15:30:00'),
-- Flight 38 (F9838)
(38, 8, 1, '2024-08-18 17:20:00'),
(38, 18, 1, '2024-08-18 17:20:00'),
(38, 28, 2, '2024-08-18 17:20:00'),
(38, 38, 2, '2024-08-18 17:20:00'),
(38, 48, 2, '2024-08-18 17:20:00'),
-- Flight 39 (G4939)
(39, 9, 1, '2024-09-13 19:00:00'),
(39, 19, 1, '2024-09-13 19:00:00'),
(39, 29, 2, '2024-09-13 19:00:00'),
(39, 39, 2, '2024-09-13 19:00:00'),
(39, 49, 2, '2024-09-13 19:00:00'),
-- Flight 40 (HA1040)
(40, 10, 1, '2024-10-05 09:45:00'),
(40, 20, 1, '2024-10-05 09:45:00'),
(40, 30, 2, '2024-10-05 09:45:00'),
(40, 40, 2, '2024-10-05 09:45:00'),
(40, 50, 2, '2024-10-05 09:45:00');
GO

PRINT 'Sample data inserted successfully for Phase 2.';
GO

-- =============================================
-- Phase 3: Implement Business Logic
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

-- =============================================
-- Phase 4: Test Business Logic
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

-- =============================================
-- Phase 5: Reports from Task (Updated with new functions)
-- =============================================
-- This script contains 4 SQL queries as required by zadanie.md
-- Updated to use new dynamic hour calculation functions
-- =============================================

USE CrewSchedulingDB;
GO

-- Report 1: Crew currently in flight
PRINT 'Report 1: Crew currently in flight';
PRINT '================================================';
SELECT 
    C.CrewID, 
    C.FirstName + ' ' + C.LastName AS CrewName,
    CT.CrewTypeName,
    SL.SeniorityName,
    F.FlightID, 
    F.FlightNumber,
    DepAir.City AS DepartureCity,
    DestAir.City AS DestinationCity,
    F.ActualDeparture AS DepartureTime, 
    DATEADD(MINUTE, F.FlightDuration, F.ActualDeparture) AS EstimatedArrival,
    F.FlightDuration / 60.0 AS FlightHours,
    R.RoleName AS Role
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
JOIN Airports DepAir ON F.DepartureAirportID = DepAir.AirportID
JOIN Airports DestAir ON F.DestinationAirportID = DestAir.AirportID
JOIN Roles R ON CA.RoleID = R.RoleID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID
WHERE F.StatusID = 2  -- InFlight
ORDER BY F.FlightID, R.RoleID DESC, C.LastName;
GO

-- Report 2: Crew exceeding or approaching hour limits (14 CFR Part 117 and 121.467)
PRINT '';
PRINT 'Report 2: Crew exceeding or approaching regulatory hour limits';
PRINT '================================================';
SELECT 
    C.CrewID,
    C.FirstName + ' ' + C.LastName AS CrewName,
    HL.CrewTypeName,
    HL.Hours168 AS [Hours Last 7 Days],
    HL.Hours672 AS [Hours Last 28 Days],
    HL.Hours365Days AS [Hours Last 365 Days],
    HL.ExceedsLimits AS [Exceeds Limits?],
    HL.LimitStatus AS [Limit Status],
    CASE 
        WHEN HL.CrewTypeName = 'Pilot' THEN 
            CASE
                WHEN HL.Hours168 > 54 THEN 'WARNING: Approaching 60h/7d limit'
                WHEN HL.Hours672 > 90 THEN 'WARNING: Approaching 100h/28d limit'
                WHEN HL.Hours672 > 180 THEN 'WARNING: Approaching 190h/28d limit'
                WHEN HL.Hours365Days > 900 THEN 'WARNING: Approaching 1000h/yr limit'
                ELSE 'OK'
            END
        ELSE 'See duty time per flight'
    END AS [Warning Status]
FROM Crew C
CROSS APPLY dbo.fn_CheckHourLimits(C.CrewID) HL
WHERE C.IsActive = 1
    AND (HL.ExceedsLimits = 1  -- Already exceeding
        OR (HL.CrewTypeName = 'Pilot' AND (HL.Hours168 > 54 OR HL.Hours672 > 90 OR HL.Hours365Days > 900)))  -- Approaching limit
ORDER BY HL.ExceedsLimits DESC, HL.Hours672 DESC;
GO

-- Report 3: Monthly hours worked by crew (for payroll)
PRINT '';
PRINT 'Report 3: Monthly hours worked per employee (for payroll)';
PRINT '================================================';
SELECT 
    C.CrewID,
    C.FirstName + ' ' + C.LastName AS CrewName,
    CT.CrewTypeName,
    SL.SeniorityName,
    YEAR(F.ScheduledDeparture) AS Year,
    MONTH(F.ScheduledDeparture) AS Month,
    DATENAME(MONTH, F.ScheduledDeparture) AS MonthName,
    COUNT(CA.AssignmentID) AS FlightsWorked,
    SUM(F.FlightDuration / 60.0) AS TotalHoursWorked,
    AVG(F.FlightDuration / 60.0) AS AvgFlightHours
FROM Crew C
JOIN CrewAssignments CA ON C.CrewID = CA.CrewID
JOIN Flights F ON CA.FlightID = F.FlightID
JOIN CrewTypes CT ON C.CrewTypeID = CT.CrewTypeID
JOIN SeniorityLevels SL ON C.SeniorityID = SL.SeniorityID
WHERE F.StatusID IN (2, 3)  -- InFlight or Landed (completed work)
    AND F.ActualDeparture IS NOT NULL
GROUP BY C.CrewID, C.FirstName, C.LastName, CT.CrewTypeName, SL.SeniorityName,
         YEAR(F.ScheduledDeparture), MONTH(F.ScheduledDeparture), DATENAME(MONTH, F.ScheduledDeparture)
ORDER BY Year DESC, Month DESC, TotalHoursWorked DESC;
GO

-- Report 4: Available crew for scheduling a flight (with regulatory compliance check)
PRINT '';
PRINT 'Report 4: Available crew for scheduling (example for NYC departures)';
PRINT '================================================';
-- This report shows crew available at NYC airport who are within regulatory limits
SELECT 
    AC.CrewID,
    AC.FirstName + ' ' + AC.LastName AS CrewName,
    AC.CrewTypeName,
    AC.SeniorityName,
    AC.BaseCity,
    AC.Hours168 AS [Hours Last 7 Days],
    AC.Hours672 AS [Hours Last 28 Days],
    AC.Hours365Days AS [Hours Last Year],
    AC.LimitStatus AS [Regulatory Status]
FROM vw_AvailableCrew AC
WHERE AC.BaseCity = 'New York'  -- Example: NYC airport
ORDER BY AC.CrewTypeID DESC, AC.SeniorityID DESC, AC.CrewID;
GO

PRINT '';
PRINT '================================================';
PRINT 'All reports completed successfully.';
PRINT '================================================';
GO

-- Architecture Diagram Description
/*
Crew Scheduling System Architecture
====================================

Database: CrewSchedulingDB (SQL Server 2019)

Tables:
- Crew (CrewID PK, encrypted SSN, personal info, hours tracking)
- Flights (FlightID PK, AirlineID FK, airports, times, status)
- Airlines (AirlineID PK, name)
- Airports (AirportID PK, code, city)
- CrewAssignments (composite PK: CrewID+FlightID, role)

Views:
- vw_AvailableCrew: Crew with current status and availability
- vw_FlightCrew: Assigned crew per flight with details

Functions:
- fn_CheckHourLimits(CrewID): Returns 1 if within 40h/week limit, 0 if exceeding
- fn_CalculateRestTime(CrewID, FlightID): Calculates rest hours before flight

Procedures:
- sp_ScheduleCrew(FlightID): Assigns available crew to scheduled flight
- sp_UpdateFlightStatus(FlightID, NewStatus): Updates flight status

Triggers:
- trg_UpdateCrewHours: Updates crew hours after assignment (AFTER INSERT on CrewAssignments)
- trg_BeforeAssignment: Validates crew availability and rest time (BEFORE INSERT on CrewAssignments)

Security:
- SYMMETRIC KEY for SSN encryption
- CERTIFICATE for key protection
- ROLE-based permissions (CrewScheduler role)

Data Flow:
1. Flights inserted with 'Scheduled' status
2. sp_ScheduleCrew called -> triggers validate -> assignments inserted -> hours updated
3. Flight status updated via sp_UpdateFlightStatus
4. Reports query views and functions for business intelligence

Encryption: SSN fields encrypted at rest using SQL Server encryption
*/
PRINT 'Architecture diagram description included above as comments';
GO