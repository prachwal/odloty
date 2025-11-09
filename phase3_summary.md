# Podsumowanie Fazy 3: Przygotowanie Logiki dla CrewSchedulingDB

## Opis Fazy

Faza 3 obejmowała implementację logiki biznesowej dla systemu Crew Scheduling, w tym stored procedures, functions, views i triggers, aby zapewnić automatyczne schedulowanie załogi, walidację limitów godzin oraz aktualizację danych zgodnie z wymaganiami z `zadanie.md` i `crew_scheduling_plan.md`.

## Wykonane Zadania

### 1. Implementacja Functions

- **fn_CheckHourLimits**: Funkcja sprawdzająca, czy członek załogi przekracza limity godzin (piloci: 100h/672h, 60h/168h, 190h/672h; FA: 14h/168h krajowe, 20h międzynarodowe).
- **fn_CalculateRestTime**: Funkcja obliczająca czas odpoczynku między lotami dla FA (minimum 9h).

### 2. Implementacja Views

- **vw_AvailableCrew**: Widok dostępnej załogi w mieście, bez przekroczeń limitów godzin.
- **vw_FlightCrew**: Widok załogi przypisanej do lotu, z nazwiskami i rolami.

### 3. Implementacja Stored Procedures

- **sp_ScheduleCrew**: Procedura schedulująca załogę dla lotu (FlightID) – znajduje dostępną załogę w DepartureCity, sprawdza limity, przypisuje 2 pilotów (min 1 senior) + 3 FA (min 1 senior), aktualizuje Hours*.
- **sp_UpdateFlightStatus**: Procedura aktualizująca status lotu (Scheduled/InFlight/Landed) i logująca czasy odlotu.

### 4. Implementacja Triggers

- **trg_AfterAssignment**: Trigger AFTER INSERT na CrewAssignments – aktualizuje HoursLast* w Crew po przypisaniu.
- **trg_BeforeAssignment**: Trigger INSTEAD OF INSERT na CrewAssignments – waliduje przed przypisaniem (miasto, limity godzin, czas odpoczynku dla FA).

## Pliki Utworzone

- `03_crew_logic.sql`: Skrypt z definicjami wszystkich SP, functions, views i triggers, idempotentny (DROP IF EXISTS).

## Kryteria Zakończenia

- Wszystkie obiekty utworzone bez błędów.
- sp_ScheduleCrew przypisuje załogę zgodnie z regułami (min seniority, limity godzin).
- Triggers walidują i blokują nieprawidłowe przypisania (np. przekroczenia limitów, brak odpoczynku).
- Views zwracają poprawne dane dla dostępnych crew i przypisań.

## Następne Kroki

Przejść do Fazy 4: Testy Logiki (testy jednostkowe i integracyjne dla wszystkich SP, functions, triggers i views).
