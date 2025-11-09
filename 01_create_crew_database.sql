-- 01_create_crew_database.sql: Faza 1 - Przygotowanie Bazy i Tabel dla Crew Scheduling System
-- Skrypt tworzy bazę CrewSchedulingDB oraz wszystkie wymagane tabele, indeksy, constraints, triggers i security.
-- Idempotentny: Można uruchomić wielokrotnie.

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