# Podsumowanie Fazy 2: Przygotowanie Danych dla CrewSchedulingDB

## Opis Fazy

Faza 2 obejmowała przygotowanie i wstawienie przykładowych danych do bazy danych `CrewSchedulingDB`, aby pokryć wszystkie scenariusze testów i raportów zgodnie z wymaganiami z `zadanie.md` i `crew_scheduling_plan.md`.

## Wykonane Zadania

### 1. Wstawienie Danych dla Załogi (Crew)

- **Liczba rekordów:** 50 osób (20 pilotów, 30 członków kabinowej).
- **Rozkład:**
  - Piloci: 20 osób (różne poziomy seniority: Trainee, Journeyman, Senior).
  - Członkowie kabinowej (FA): 30 osób (różne poziomy seniority).
- **Miasta:** Różne miasta, w tym NYC, Burlington, Chicago, Los Angeles, Miami, Seattle, Denver, Boston, San Francisco, Dallas.
- **Godziny pracy:** Symulowane godziny z ostatnich okresów (Last40, Last7, Last28), w tym przypadki przekraczające limity dla pilotów (np. >100h/672h) i FA (np. >14h krajowe).
- **Bezpieczeństwo:** SSN zaszyfrowane przy użyciu ENCRYPTBYKEY z kluczem symetrycznym.

### 2. Wstawienie Danych dla Lotów (Flights)

- **Liczba rekordów:** 100 lotów.
- **Linie lotnicze:** 10 różnych linii (American Airlines, Delta, United, itp.).
- **Miasta:** Połączenia między wymienionymi miastami.
- **Czas trwania:** Od 80 do 360 minut.
- **Statusy:** Scheduled, InFlight, Landed (w tym bieżące loty w powietrzu).
- **Dane historyczne:** Loty z ostatnich 2 lat (od 2023-11-09 do 2025-11-09).

### 3. Wstawienie Danych dla Lotnisk i Linii Lotniczych

- **Lotniska (Airports):** 10 rekordów z kodami IATA.
- **Linie lotnicze (Airlines):** 10 rekordów z kodami IATA.

### 4. Wstawienie Przypisań Załogi (CrewAssignments)

- **Liczba rekordów:** 200 przypisań.
- **Struktura:** 5 osób na lot (2 piloci + 3 FA), z rolami Pilot/Cabin.
- **Historia godzin:** Przypisania do lotów historycznych, aby zbudować historię godzin pracy.
- **Pokrycie scenariuszy:** Piloci przekraczający limity, FA z krótkimi przerwami między lotami (<9h).

## Pliki Utworzone

- `02_insert_crew_data.sql`: Skrypt INSERT z idempotentnymi operacjami (DELETE + DBCC CHECKIDENT).

## Kryteria Zakończenia

- Dane wstawione bez błędów FK.
- Pokrycie wszystkich scenariuszy: przekroczenia limitów, różnorodność miast, dane historyczne.
- Queries testowe zwracają oczekiwane wyniki (np. załoga w locie, przekroczenia limitów).

## Następne Kroki

Przejść do Fazy 3: Przygotowanie Logiki (stored procedures, functions, views, triggers).
