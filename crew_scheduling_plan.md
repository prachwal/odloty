# Plan Implementacji Systemu Crew Scheduling

## Opis Projektu

Na podstawie `zadanie.md` ("DESIGNING AN ARCHITECTURE FOR WORLDWIDE CREW SCHEDULING"), projekt obejmuje zaprojektowanie i implementację bazy danych oraz aplikacji dla schedulingu załóg lotniczych. System zapewnia zgodność z regulacjami (14 CFR Part 117/121.467), równomierne rozłożenie pracy oraz wysoką dostępność (99.9999% uptime).

Kluczowe wymagania:

- Załoga: 2 pilotów (min 1 senior), 3 członków kabinowej (min 1 senior).
- Ograniczenia godzin: Piloci (100h/672h, 1000h/365d, 60h/168h, 190h/672h), stewardzi (14h krajowe, 20h międzynarodowe, 9h między lotami).
- Raporty: Załoga w locie, przekroczenia limitów, godziny pracy miesięcznie.
- Architektura: Multiple serwery dla redundancji.

---

## Faza 1: Przygotowanie Bazy i Tabel

**Cel:** Zaprojektować i utworzyć bazę danych `CrewSchedulingDB` z tabelami, indeksami, constraints i triggers dla podstawowych danych.

**Zadania:**

- Utworzyć bazę z collation `SQL_Latin1_General_CP1_CI_AS`, recovery model `FULL`, compatibility level 150.
- Tabele główne:
  - `Crew`: CrewID (PK), FirstName, LastName, SSN (encrypted), CurrentCity, CrewType (1=FA, 2=Pilot), Seniority (1=Trainee, 2=Journeyman, 3=Senior), HoursLast40, HoursLast7, HoursLast28, IsActive.
  - `Flights`: FlightID (PK), Airline, FlightNumber, DepartureCity, DestinationCity, FlightDuration, ScheduledDeparture (DATETIME2), ActualDeparture (DATETIME2), Status (Scheduled/InFlight/Landed).
  - `CrewAssignments`: AssignmentID (PK), FlightID (FK), CrewID (FK), Role (Pilot/Cabin), AssignedAt (DATETIME2).
  - `Airports`: AirportID (PK), City, Country, IATACode.
  - `Airlines`: AirlineID (PK), AirlineName, IATACode.
- Indeksy: Na Crew.CurrentCity, Flights.DepartureCity, Flights.Status, CrewAssignments.FlightID/CrewID.
- Constraints: CHECK na CrewType/Seniority, UNIQUE na SSN (encrypted), FK między tabelami.
- Triggers: Automatyczne aktualizacje HoursLast* przy przypisaniu lotu.
- Security: Szyfrowanie SSN (Always Encrypted lub TDE), role użytkowników (StationManager, FlightOps, Compliance, HR).

**Pliki wyjściowe:** `create_crew_database.sql` (DDL).

**Kryteria zakończenia:** Baza utworzona, tabele z danymi testowymi, brak błędów FK.

---

## Faza 2: Przygotowanie Danych

**Cel:** Wstawić przykładowe dane do pokrycia wszystkich scenariuszy testów i raportów.

**Zadania:**

- Wstawić dane dla 50 crew (20 pilotów, 30 FA, różne seniority, miasta).
- Wstawić dane dla 100 flights (różne airlines, miasta, duration, statusy).
- Wstawić 200 assignments (przypisania crew do flights, z historią godzin).
- Dane historyczne: Flights z ostatnich 2 lat, assignments z różnymi datami dla kalkulacji godzin.
- Pokrycie: Piloci przekraczający limity, FA z przerwami <9h, różne miasta (NYC, Burlington itp.).
- **Walidacja FK:** Wszystkie dane używają ID zamiast nazw (BaseAirportID, DepartureAirportID, DestinationAirportID). Uniknąć błędów konwersji przez używanie odpowiednich typów danych.

**Pliki wyjściowe:** `insert_crew_data.sql` (INSERT statements).

**Kryteria zakończenia:** Dane wstawione, queries zwracają oczekiwane wyniki dla testów.

---

## Faza 3: Przygotowanie Logiki

**Cel:** Zaimplementować stored procedures, functions, views i triggers dla schedulingu i walidacji.

**Zadania:**

- Stored Procedures:
  - `sp_ScheduleCrew`: Dla danego FlightID, znajdź dostępną załogę w DepartureCity, sprawdź limity godzin, przypisz (2 pilots min 1 senior, 3 cabin min 1 senior), zaktualizuj Hours*.
  - `sp_UpdateFlightStatus`: Aktualizuj status flight, loguj czasy.
- Functions:
  - `fn_CheckHourLimits`: Dla CrewID sprawdź, czy przekracza limity (piloci/FA osobno).
  - `fn_CalculateRestTime`: Dla FA sprawdź czas między lotami.
- Views:
  - `vw_AvailableCrew`: Crew dostępni w mieście, bez przekroczeń limitów.
  - `vw_FlightCrew`: Załoga przypisana do flight.
- Triggers:
  - `trg_AfterAssignment`: Po INSERT do CrewAssignments, aktualizuj Hours* w Crew.
  - `trg_BeforeAssignment`: Walidacja przed przypisaniem (limity, dostępność).

**Pliki wyjściowe:** `crew_logic.sql` (SP, functions, views, triggers).

**Kryteria zakończenia:** Logika działa, sp_ScheduleCrew przypisuje poprawnie, walidacje blokują nieprawidłowe przypisania.

---

## Faza 4: Testy Logiki

**Cel:** Przetestować wszystkie SP, functions, triggers i views.

**Zadania:**

- Testy jednostkowe:
  - `fn_CheckHourLimits`: Test dla pilotów przekraczających 100h/672h, FA z <9h rest.
  - `sp_ScheduleCrew`: Test sukcesu (przypisanie), porażki (brak crew, przekroczenia).
  - Triggers: Test aktualizacji Hours* po assignment.
- Testy integracyjne:
  - End-to-end: Schedule crew → Update status → Check limits.
  - Współbieżność: Multiple schedules dla tego samego crew.
- Testy wydajnościowe:
  - sp_ScheduleCrew dla 1000 crew/flights, czas <2s.
  - Views z JOIN na dużych danych.

**Pliki wyjściowe:** `test_crew_logic.sql` (test scripts z ASSERT/PRINT).

**Kryteria zakończenia:** Wszystkie testy pass, logika stabilna.

---

## Faza 5: Raporty z Zadania

**Cel:** Zaimplementować 4 wymagane raporty i diagram architektury.

**Zadania:**

- Raporty T-SQL:
  1. **Crew on planes currently in flight:** SELECT z Flights WHERE Status='InFlight' JOIN CrewAssignments.
  2. **Crew exceeding hour limits:** SELECT Crew WHERE fn_CheckHourLimits=1, z podziałem na typy limitów.
  3. **Hours worked per month per employee:** GROUP BY CrewID, YEAR/MONTH, SUM Hours z Assignments.
  4. **Schedule crew query:** sp_ScheduleCrew (jako dodatkowy).
- Diagram architektury: Opis/logiczny diagram dla 99.9999% uptime (load balancer, primary/secondary servers, failover, geo-redundancja).
- Security: Rekomendacje (encryption, access controls).

**Pliki wyjściowe:** `crew_reports.sql` (queries), `architecture_diagram.md` (opis diagramu).

**Kryteria zakończenia:** Raporty zwracają poprawne dane, diagram kompletny.

---

## Stan Realizacji

- **Faza 1**: Ukończona ✅ - Plik `01_create_crew_database.sql` utworzony.
- **Faza 2**: Ukończona ✅ - Plik `02_insert_crew_data.sql` utworzony i wykonany.
- **Faza 3**: Ukończona ✅ - Plik `03_crew_logic.sql` utworzony.
- **Faza 4**: Ukończona ✅ - Plik `04_test_crew_logic.sql` utworzony.
- **Faza 5**: Ukończona ✅ - Pliki `05_reports.sql`, `phase5_summary.md` utworzone.

## Następne Kroki

Rozpocząć od Fazy 1. Jeśli potrzebujesz modyfikacji planu, daj znać!
