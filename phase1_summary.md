# Podsumowanie Fazy 1: Przygotowanie Bazy i Tabel

## Opis Fazy

Faza 1 polega na zaprojektowaniu i utworzeniu bazy danych `CrewSchedulingDB` wraz z tabelami, indeksami, constraints, triggers i podstawowymi ustawieniami security, zgodnie z wymaganiami z `zadanie.md` i planu.

## Pliki Wygenerowane

- **`01_create_crew_database.sql`**: Główny skrypt DDL tworzący bazę i wszystkie obiekty.

## Struktura Bazy i Tabel Utworzonych

### Baza Danych

- **Nazwa**: CrewSchedulingDB
- **Collation**: SQL_Latin1_General_CP1_CI_AS
- **Recovery Model**: FULL
- **Compatibility Level**: 150 (SQL Server 2019)

### Tabele

- **Airlines**: AirlineID (PK), AirlineName, IATACode (UNIQUE).
- **Airports**: AirportID (PK), City, Country, IATACode (UNIQUE).
- **Crew**: CrewID (PK), FirstName, LastName, SSN (VARBINARY, encrypted), CurrentCity, CrewType (1=FA, 2=Pilot), Seniority (1-3), HoursLast40/7/28, IsActive.
- **Flights**: FlightID (PK), Airline, FlightNumber, DepartureCity, DestinationCity, FlightDuration, ScheduledDeparture, ActualDeparture, Status (Scheduled/InFlight/Landed).
- **CrewAssignments**: AssignmentID (PK), FlightID (FK), CrewID (FK), Role (Pilot/Cabin), AssignedAt.

### Indeksy

- IX_Crew_CurrentCity
- IX_Flights_DepartureCity
- IX_Flights_Status
- IX_CrewAssignments_FlightID
- IX_CrewAssignments_CrewID

### Constraints

- CHECK na CrewType, Seniority, Status, Role.
- UNIQUE na IATACode w Airlines/Airports, SSN w Crew.
- FOREIGN KEY między CrewAssignments a Flights/Crew.

### Triggers

- **trg_UpdateCrewHours**: AFTER INSERT na CrewAssignments – aktualizuje HoursLast* w Crew na podstawie FlightDuration (gdy ActualDeparture IS NOT NULL).

### Security

- **Szyfrowanie SSN**: CERTIFICATE (CrewSSNCert) i SYMMETRIC KEY (CrewSSNKey) dla AES_256 encryption.
- **Role użytkowników**: StationManager (schedule), FlightOps (flights), Compliance (reports), HR (crew updates).
- **Permissions**: GRANT SELECT/INSERT/UPDATE odpowiednio dla ról.

## Idempotentność i Wykonanie

- Skrypt rozpoczyna od DROP DATABASE IF EXISTS.
- Można uruchomić wielokrotnie bez błędów.
- Zakłada brak istniejącej bazy.
- Po wykonaniu: Baza gotowa do wstawiania danych w Fazie 2.

## Pokrycie Wymagań z Zadania

- Tabele dla crew, flights, assignments – zgodne z metadanymi z `zadanie.md`.
- Security dla wrażliwych danych (SSN).
- Triggers dla automatycznych aktualizacji godzin.
- Indeksy dla optymalizacji queries (np. po CurrentCity dla schedulingu).

## Następne Kroki

- Faza 2: Przygotowanie danych.
- Faza 3: Logika biznesowa.
- Faza 4: Testy.
- Faza 5: Raporty.

Jeśli potrzebujesz modyfikacji lub rozszerzeń, daj znać!
