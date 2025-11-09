# Crew Scheduling System Reports

## Task Description


# TECHNICAL AUDITION

Below is your audition scenario. Please prepare a solution to the problem described.  Please arrive ready to present your solution, in whatever fashion you feel most comfortable (e.g. whiteboard, written design, UML, PowerPoint, pseudo code, actual code), to a panel of 3 to 4 interviewers. Once you have presented your solution, the interviewers will ask questions and provide additional requirements that you will have to incorporate into your design on the fly. This process gives us a chance to see how you solve problems, how advanced your design skills are, how well you present to a group, and how well you think on your feet. The technical audition will last approximately one hour. Please let us know if you have any questions before the interview.

## DESIGNING AN ARCHITECTURE FOR WORLDWIDE CREW SCHEDULING

Consider an application to handle the scheduling of airline crews for commercial flights. This application is used by airline station managers to ensure that every departing flight has two pilots (with at least one pilot being a "senior" or "captain") and a cabin crew of three people where one of the cabin crew is a senior level flight attendant.
Each airline station manager is situated at an airport with varying levels and quality of Internet access. For example, airline station managers located in New York City have access to reliable, high-speed Internet access while station managers at smaller airports such as Burlington, Vermont may have slow or unreliable access.
For each human, the application will track the following metadata:  (at a minimum)
Full name (first and last)
Social security number
Number of hours flown in the last 40 hours
Number of hours flown in the last 7 days
Number of hours flown in the last 28 days
Crew type (1 = flight attendant / 2 = pilot)
Crew seniority (1 = trainee / 2 = journeyman / 3 = senior [i.e. captain or senior F.A])
For each flight requiring a crew, the application will track the following metadata:  (at a minimum)
Airline
Flight number
Departure city
Destination city
Flight duration
NOTE: The metadata listed above is intentionally incomplete. As in real life, new data fields (or even whole tables) may need to be incorporated into the database to achieve the design goals of the application.
The minimum viable product for the first release of this application should be able to do the following:
Allow for operational redundancy of the application by deployment to multiple servers.
Allow for station managers to run a query to schedule a crew for a departing flight. The ultimate goal is both regulatory compliance to ensure crews do not exceed flight time limitations and fairness to ensure that the work is spread as evenly as practical across all available flight personnel in a particular location. REMEMBER: crew can only be scheduled to work flights that depart from the same city in which they are currently located.
Allow for flight operations department to run a report showing all crew members on planes currently in flight.
Allow for government compliance department to run a report showing all crew members who either have exceeded or are in danger of exceeding their work hour limitations per 14 CFR Part 117 and 14 CFR Part 121.467. These limits for the purpose of this audition can be summed up as:
No pilot may fly more than 100 total hours in the last 672 hours
No pilot may fly more than 1,000 total hours in the last 365 days
No pilot may fly more than 60 hours in the last 168 consecutive hours
No pilot may fly more than 190 hours in the last 672 consecutive hours
No flight attendant may be on domestic flight duty for more than 14 consecutive hours
No flight attendant may be on international flight duty for more then 20 consecutive hours
All flight attendant require at least 9 consecutive hours between flights
Allow for human resources to run a report listing the number of hours worked per month (and when) on a per employee basis to support payroll.
Design the database to implement this application, including any tables, indexes, views, triggers, and constraints that may be needed. Write the appropriate T-SQL queries to implement the four reports listed above, and provide a logical diagram depicting how the servers supporting this application will be configured to support 99.9999% up time.
Remember to consider the security requirements of each piece of information stored in the database.
    

## Report 1: Crew currently in flight

This report shows all crew members currently on planes in flight, including their flight details and roles.

|   Crew | First Name   | Last Name   |   Flight | Flight Number   | Departure City   | Destination City   | Departure Time             | Arrival Time               | Role   | Seniority   |
|-------:|:-------------|:------------|---------:|:----------------|:-----------------|:-------------------|:---------------------------|:---------------------------|:-------|:------------|
|     42 | Isabella     | Mendoza     |        2 | DL202           | Burlington       | Miami              | 2024-02-20 10:35:00        | 2024-02-20 13:35:00        | Cabin  | Senior      |
|     22 | Daniel       | Morales     |        2 | DL202           | Burlington       | Miami              | 2024-02-20 10:35:00        | 2024-02-20 13:35:00        | Cabin  | Journeyman  |
|     32 | Madison      | Romero      |        2 | DL202           | Burlington       | Miami              | 2024-02-20 10:35:00        | 2024-02-20 13:35:00        | Cabin  | Trainee     |
|     12 | Karen        | Lopez       |        2 | DL202           | Burlington       | Miami              | 2024-02-20 10:35:00        | 2024-02-20 13:35:00        | Pilot  | Trainee     |
|      2 | Jane         | Smith       |        2 | DL202           | Burlington       | Miami              | 2024-02-20 10:35:00        | 2024-02-20 13:35:00        | Pilot  | Journeyman  |
|     33 | Jordan       | Herrera     |        3 | UA303           | Los Angeles      | Seattle            | 2024-03-10 14:10:00        | 2024-03-10 16:40:00        | Cabin  | Senior      |
|     23 | Ashley       | Ortiz       |        3 | UA303           | Los Angeles      | Seattle            | 2024-03-10 14:10:00        | 2024-03-10 16:40:00        | Cabin  | Trainee     |
|     43 | Mason        | Silva       |        3 | UA303           | Los Angeles      | Seattle            | 2024-03-10 14:10:00        | 2024-03-10 16:40:00        | Cabin  | Journeyman  |
|     13 | Mark         | Gonzalez    |        3 | UA303           | Los Angeles      | Seattle            | 2024-03-10 14:10:00        | 2024-03-10 16:40:00        | Pilot  | Senior      |
|      3 | Mike         | Johnson     |        3 | UA303           | Los Angeles      | Seattle            | 2024-03-10 14:10:00        | 2024-03-10 16:40:00        | Pilot  | Trainee     |
|     24 | Tyler        | Gutierrez   |        4 | WN404           | Denver           | Dallas             | 2024-04-05 16:50:00        | 2024-04-05 18:20:00        | Cabin  | Senior      |
|     34 | Alexis       | Medina      |        4 | WN404           | Denver           | Dallas             | 2024-04-05 16:50:00        | 2024-04-05 18:20:00        | Cabin  | Journeyman  |
|     44 | Sophia       | Pena        |        4 | WN404           | Denver           | Dallas             | 2024-04-05 16:50:00        | 2024-04-05 18:20:00        | Cabin  | Trainee     |
|      4 | Emily        | Davis       |        4 | WN404           | Denver           | Dallas             | 2024-04-05 16:50:00        | 2024-04-05 18:20:00        | Pilot  | Senior      |
|     14 | Rachel       | Perez       |        4 | WN404           | Denver           | Dallas             | 2024-04-05 16:50:00        | 2024-04-05 18:20:00        | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |        5 | B6505           | Boston           | San Francisco      | 2024-05-12 09:20:00        | 2024-05-12 14:20:00        | Cabin  | Journeyman  |
|     35 | Cameron      | Cortes      |        5 | B6505           | Boston           | San Francisco      | 2024-05-12 09:20:00        | 2024-05-12 14:20:00        | Cabin  | Trainee     |
|     45 | Logan        | Reyes       |        5 | B6505           | Boston           | San Francisco      | 2024-05-12 09:20:00        | 2024-05-12 14:20:00        | Cabin  | Senior      |
|     15 | Steve        | Sanchez     |        5 | B6505           | Boston           | San Francisco      | 2024-05-12 09:20:00        | 2024-05-12 14:20:00        | Pilot  | Trainee     |
|      5 | David        | Wilson      |        5 | B6505           | Boston           | San Francisco      | 2024-05-12 09:20:00        | 2024-05-12 14:20:00        | Pilot  | Journeyman  |
|     46 | Ava          | Cruz        |        6 | AS606           | New York         | Seattle            | 2024-06-18 11:05:00        | 2024-06-18 15:15:00        | Cabin  | Journeyman  |
|     26 | Justin       | Ramos       |        6 | AS606           | New York         | Seattle            | 2024-06-18 11:05:00        | 2024-06-18 15:15:00        | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |        6 | AS606           | New York         | Seattle            | 2024-06-18 11:05:00        | 2024-06-18 15:15:00        | Cabin  | Senior      |
|      6 | Sarah        | Brown       |        6 | AS606           | New York         | Seattle            | 2024-06-18 11:05:00        | 2024-06-18 15:15:00        | Pilot  | Trainee     |
|     16 | Laura        | Ramirez     |        6 | AS606           | New York         | Seattle            | 2024-06-18 11:05:00        | 2024-06-18 15:15:00        | Pilot  | Senior      |
|     47 | Jackson      | Fernandez   |        7 | NK707           | Dallas           | Boston             | 2024-07-22 13:35:00        | 2024-07-22 15:55:00        | Cabin  | Trainee     |
|     27 | Hannah       | Guzman      |        7 | NK707           | Dallas           | Boston             | 2024-07-22 13:35:00        | 2024-07-22 15:55:00        | Cabin  | Senior      |
|     37 | Dylan        | Luna        |        7 | NK707           | Dallas           | Boston             | 2024-07-22 13:35:00        | 2024-07-22 15:55:00        | Cabin  | Journeyman  |
|      7 | Chris        | Miller      |        7 | NK707           | Dallas           | Boston             | 2024-07-22 13:35:00        | 2024-07-22 15:55:00        | Pilot  | Senior      |
|     17 | Kevin        | Torres      |        7 | NK707           | Dallas           | Boston             | 2024-07-22 13:35:00        | 2024-07-22 15:55:00        | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |        8 | F9808           | Miami            | San Francisco      | 2024-08-14 15:25:00        | 2024-08-14 18:05:00        | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |        8 | F9808           | Miami            | San Francisco      | 2024-08-14 15:25:00        | 2024-08-14 18:05:00        | Cabin  | Trainee     |
|     48 | Mia          | Ruiz        |        8 | F9808           | Miami            | San Francisco      | 2024-08-14 15:25:00        | 2024-08-14 18:05:00        | Cabin  | Senior      |
|     18 | Jessica      | Flores      |        8 | F9808           | Miami            | San Francisco      | 2024-08-14 15:25:00        | 2024-08-14 18:05:00        | Pilot  | Trainee     |
|      8 | Anna         | Garcia      |        8 | F9808           | Miami            | San Francisco      | 2024-08-14 15:25:00        | 2024-08-14 18:05:00        | Pilot  | Journeyman  |
|     49 | Liam         | Alvarez     |        9 | G4909           | Los Angeles      | Burlington         | 2024-09-09 17:05:00        | 2024-09-09 18:55:00        | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |        9 | G4909           | Los Angeles      | Burlington         | 2024-09-09 17:05:00        | 2024-09-09 18:55:00        | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |        9 | G4909           | Los Angeles      | Burlington         | 2024-09-09 17:05:00        | 2024-09-09 18:55:00        | Cabin  | Trainee     |
|     19 | Brian        | Rivera      |        9 | G4909           | Los Angeles      | Burlington         | 2024-09-09 17:05:00        | 2024-09-09 18:55:00        | Pilot  | Senior      |
|      9 | Tom          | Rodriguez   |        9 | G4909           | Los Angeles      | Burlington         | 2024-09-09 17:05:00        | 2024-09-09 18:55:00        | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       10 | HA1010          | Boston           | Denver             | 2024-10-01 07:50:00        | 2024-10-01 09:30:00        | Cabin  | Journeyman  |
|     50 | Charlotte    | Morales     |       10 | HA1010          | Boston           | Denver             | 2024-10-01 07:50:00        | 2024-10-01 09:30:00        | Cabin  | Trainee     |
|     30 | Austin       | Moreno      |       10 | HA1010          | Boston           | Denver             | 2024-10-01 07:50:00        | 2024-10-01 09:30:00        | Cabin  | Senior      |
|     20 | Amanda       | Gomez       |       10 | HA1010          | Boston           | Denver             | 2024-10-01 07:50:00        | 2024-10-01 09:30:00        | Pilot  | Journeyman  |
|     10 | Lisa         | Martinez    |       10 | HA1010          | Boston           | Denver             | 2024-10-01 07:50:00        | 2024-10-01 09:30:00        | Pilot  | Senior      |
|     21 | Nicole       | Diaz        |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Cabin  | Senior      |
|     41 | Nathan       | Soto        |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Cabin  | Trainee     |
|     31 | Taylor       | Vargas      |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Cabin  | Journeyman  |
|      4 | Emily        | Davis       |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Pilot  | Senior      |
|      1 | John         | Doe         |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Pilot  | Senior      |
|     11 | Paul         | Hernandez   |       11 | AA111           | Seattle          | Miami              | 2024-11-01 08:05:00        | 2024-11-01 11:25:00        | Pilot  | Journeyman  |
|     42 | Isabella     | Mendoza     |       12 | DL212           | Boston           | Los Angeles        | 2024-12-05 10:35:00        | 2024-12-05 14:35:00        | Cabin  | Senior      |
|     22 | Daniel       | Morales     |       12 | DL212           | Boston           | Los Angeles        | 2024-12-05 10:35:00        | 2024-12-05 14:35:00        | Cabin  | Journeyman  |
|     32 | Madison      | Romero      |       12 | DL212           | Boston           | Los Angeles        | 2024-12-05 10:35:00        | 2024-12-05 14:35:00        | Cabin  | Trainee     |
|     12 | Karen        | Lopez       |       12 | DL212           | Boston           | Los Angeles        | 2024-12-05 10:35:00        | 2024-12-05 14:35:00        | Pilot  | Trainee     |
|      2 | Jane         | Smith       |       12 | DL212           | Boston           | Los Angeles        | 2024-12-05 10:35:00        | 2024-12-05 14:35:00        | Pilot  | Journeyman  |
|     33 | Jordan       | Herrera     |       13 | UA313           | San Francisco    | Chicago            | 2025-01-10 14:10:00        | 2025-01-10 19:30:00        | Cabin  | Senior      |
|     23 | Ashley       | Ortiz       |       13 | UA313           | San Francisco    | Chicago            | 2025-01-10 14:10:00        | 2025-01-10 19:30:00        | Cabin  | Trainee     |
|     43 | Mason        | Silva       |       13 | UA313           | San Francisco    | Chicago            | 2025-01-10 14:10:00        | 2025-01-10 19:30:00        | Cabin  | Journeyman  |
|     13 | Mark         | Gonzalez    |       13 | UA313           | San Francisco    | Chicago            | 2025-01-10 14:10:00        | 2025-01-10 19:30:00        | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       13 | UA313           | San Francisco    | Chicago            | 2025-01-10 14:10:00        | 2025-01-10 19:30:00        | Pilot  | Trainee     |
|     24 | Tyler        | Gutierrez   |       14 | WN414           | Dallas           | Burlington         | 2025-02-15 16:50:00        | 2025-02-15 19:30:00        | Cabin  | Senior      |
|     34 | Alexis       | Medina      |       14 | WN414           | Dallas           | Burlington         | 2025-02-15 16:50:00        | 2025-02-15 19:30:00        | Cabin  | Journeyman  |
|     44 | Sophia       | Pena        |       14 | WN414           | Dallas           | Burlington         | 2025-02-15 16:50:00        | 2025-02-15 19:30:00        | Cabin  | Trainee     |
|      4 | Emily        | Davis       |       14 | WN414           | Dallas           | Burlington         | 2025-02-15 16:50:00        | 2025-02-15 19:30:00        | Pilot  | Senior      |
|     14 | Rachel       | Perez       |       14 | WN414           | Dallas           | Burlington         | 2025-02-15 16:50:00        | 2025-02-15 19:30:00        | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |       15 | B6515           | New York         | Seattle            | 2025-03-20 09:20:00        | 2025-03-20 13:30:00        | Cabin  | Journeyman  |
|     35 | Cameron      | Cortes      |       15 | B6515           | New York         | Seattle            | 2025-03-20 09:20:00        | 2025-03-20 13:30:00        | Cabin  | Trainee     |
|     45 | Logan        | Reyes       |       15 | B6515           | New York         | Seattle            | 2025-03-20 09:20:00        | 2025-03-20 13:30:00        | Cabin  | Senior      |
|     15 | Steve        | Sanchez     |       15 | B6515           | New York         | Seattle            | 2025-03-20 09:20:00        | 2025-03-20 13:30:00        | Pilot  | Trainee     |
|      5 | David        | Wilson      |       15 | B6515           | New York         | Seattle            | 2025-03-20 09:20:00        | 2025-03-20 13:30:00        | Pilot  | Journeyman  |
|     46 | Ava          | Cruz        |       16 | AS616           | Miami            | Boston             | 2025-04-25 11:05:00        | 2025-04-25 13:15:00        | Cabin  | Journeyman  |
|     26 | Justin       | Ramos       |       16 | AS616           | Miami            | Boston             | 2025-04-25 11:05:00        | 2025-04-25 13:15:00        | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |       16 | AS616           | Miami            | Boston             | 2025-04-25 11:05:00        | 2025-04-25 13:15:00        | Cabin  | Senior      |
|      6 | Sarah        | Brown       |       16 | AS616           | Miami            | Boston             | 2025-04-25 11:05:00        | 2025-04-25 13:15:00        | Pilot  | Trainee     |
|     16 | Laura        | Ramirez     |       16 | AS616           | Miami            | Boston             | 2025-04-25 11:05:00        | 2025-04-25 13:15:00        | Pilot  | Senior      |
|     47 | Jackson      | Fernandez   |       17 | NK717           | Los Angeles      | Dallas             | 2025-05-30 13:35:00        | 2025-05-30 18:15:00        | Cabin  | Trainee     |
|     27 | Hannah       | Guzman      |       17 | NK717           | Los Angeles      | Dallas             | 2025-05-30 13:35:00        | 2025-05-30 18:15:00        | Cabin  | Senior      |
|     37 | Dylan        | Luna        |       17 | NK717           | Los Angeles      | Dallas             | 2025-05-30 13:35:00        | 2025-05-30 18:15:00        | Cabin  | Journeyman  |
|      7 | Chris        | Miller      |       17 | NK717           | Los Angeles      | Dallas             | 2025-05-30 13:35:00        | 2025-05-30 18:15:00        | Pilot  | Senior      |
|     17 | Kevin        | Torres      |       17 | NK717           | Los Angeles      | Dallas             | 2025-05-30 13:35:00        | 2025-05-30 18:15:00        | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |       18 | F9818           | Burlington       | San Francisco      | 2025-06-05 15:25:00        | 2025-06-05 17:55:00        | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |       18 | F9818           | Burlington       | San Francisco      | 2025-06-05 15:25:00        | 2025-06-05 17:55:00        | Cabin  | Trainee     |
|     48 | Mia          | Ruiz        |       18 | F9818           | Burlington       | San Francisco      | 2025-06-05 15:25:00        | 2025-06-05 17:55:00        | Cabin  | Senior      |
|     18 | Jessica      | Flores      |       18 | F9818           | Burlington       | San Francisco      | 2025-06-05 15:25:00        | 2025-06-05 17:55:00        | Pilot  | Trainee     |
|      8 | Anna         | Garcia      |       18 | F9818           | Burlington       | San Francisco      | 2025-06-05 15:25:00        | 2025-06-05 17:55:00        | Pilot  | Journeyman  |
|     49 | Liam         | Alvarez     |       19 | G4919           | Chicago          | New York           | 2025-07-10 17:05:00        | 2025-07-10 22:05:00        | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |       19 | G4919           | Chicago          | New York           | 2025-07-10 17:05:00        | 2025-07-10 22:05:00        | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |       19 | G4919           | Chicago          | New York           | 2025-07-10 17:05:00        | 2025-07-10 22:05:00        | Cabin  | Trainee     |
|     19 | Brian        | Rivera      |       19 | G4919           | Chicago          | New York           | 2025-07-10 17:05:00        | 2025-07-10 22:05:00        | Pilot  | Senior      |
|      9 | Tom          | Rodriguez   |       19 | G4919           | Chicago          | New York           | 2025-07-10 17:05:00        | 2025-07-10 22:05:00        | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       20 | HA1020          | Denver           | Miami              | 2025-08-15 07:50:00        | 2025-08-15 10:40:00        | Cabin  | Journeyman  |
|     50 | Charlotte    | Morales     |       20 | HA1020          | Denver           | Miami              | 2025-08-15 07:50:00        | 2025-08-15 10:40:00        | Cabin  | Trainee     |
|     30 | Austin       | Moreno      |       20 | HA1020          | Denver           | Miami              | 2025-08-15 07:50:00        | 2025-08-15 10:40:00        | Cabin  | Senior      |
|     20 | Amanda       | Gomez       |       20 | HA1020          | Denver           | Miami              | 2025-08-15 07:50:00        | 2025-08-15 10:40:00        | Pilot  | Journeyman  |
|     10 | Lisa         | Martinez    |       20 | HA1020          | Denver           | Miami              | 2025-08-15 07:50:00        | 2025-08-15 10:40:00        | Pilot  | Senior      |
|     21 | Nicole       | Diaz        |       21 | AA121           | New York         | Seattle            | 2025-09-01 08:05:00        | 2025-09-01 23:05:00        | Cabin  | Senior      |
|     41 | Nathan       | Soto        |       21 | AA121           | New York         | Seattle            | 2025-09-01 08:05:00        | 2025-09-01 23:05:00        | Cabin  | Trainee     |
|     31 | Taylor       | Vargas      |       21 | AA121           | New York         | Seattle            | 2025-09-01 08:05:00        | 2025-09-01 23:05:00        | Cabin  | Journeyman  |
|      1 | John         | Doe         |       21 | AA121           | New York         | Seattle            | 2025-09-01 08:05:00        | 2025-09-01 23:05:00        | Pilot  | Senior      |
|     11 | Paul         | Hernandez   |       21 | AA121           | New York         | Seattle            | 2025-09-01 08:05:00        | 2025-09-01 23:05:00        | Pilot  | Journeyman  |
|     42 | Isabella     | Mendoza     |       22 | DL222           | Boston           | Los Angeles        | 2025-09-15 10:35:00        | 2025-09-16 04:35:00        | Cabin  | Senior      |
|     22 | Daniel       | Morales     |       22 | DL222           | Boston           | Los Angeles        | 2025-09-15 10:35:00        | 2025-09-16 04:35:00        | Cabin  | Journeyman  |
|     32 | Madison      | Romero      |       22 | DL222           | Boston           | Los Angeles        | 2025-09-15 10:35:00        | 2025-09-16 04:35:00        | Cabin  | Trainee     |
|     12 | Karen        | Lopez       |       22 | DL222           | Boston           | Los Angeles        | 2025-09-15 10:35:00        | 2025-09-16 04:35:00        | Pilot  | Trainee     |
|      2 | Jane         | Smith       |       22 | DL222           | Boston           | Los Angeles        | 2025-09-15 10:35:00        | 2025-09-16 04:35:00        | Pilot  | Journeyman  |
|     33 | Jordan       | Herrera     |       23 | UA323           | San Francisco    | Burlington         | 2025-10-01 14:10:00        | 2025-10-02 02:10:00        | Cabin  | Senior      |
|     23 | Ashley       | Ortiz       |       23 | UA323           | San Francisco    | Burlington         | 2025-10-01 14:10:00        | 2025-10-02 02:10:00        | Cabin  | Trainee     |
|     43 | Mason        | Silva       |       23 | UA323           | San Francisco    | Burlington         | 2025-10-01 14:10:00        | 2025-10-02 02:10:00        | Cabin  | Journeyman  |
|     13 | Mark         | Gonzalez    |       23 | UA323           | San Francisco    | Burlington         | 2025-10-01 14:10:00        | 2025-10-02 02:10:00        | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       23 | UA323           | San Francisco    | Burlington         | 2025-10-01 14:10:00        | 2025-10-02 02:10:00        | Pilot  | Trainee     |
|     24 | Tyler        | Gutierrez   |       24 | WN424           | Miami            | Chicago            | 2025-10-15 16:50:00        | 2025-10-16 11:50:00        | Cabin  | Senior      |
|     34 | Alexis       | Medina      |       24 | WN424           | Miami            | Chicago            | 2025-10-15 16:50:00        | 2025-10-16 11:50:00        | Cabin  | Journeyman  |
|     44 | Sophia       | Pena        |       24 | WN424           | Miami            | Chicago            | 2025-10-15 16:50:00        | 2025-10-16 11:50:00        | Cabin  | Trainee     |
|      4 | Emily        | Davis       |       24 | WN424           | Miami            | Chicago            | 2025-10-15 16:50:00        | 2025-10-16 11:50:00        | Pilot  | Senior      |
|     14 | Rachel       | Perez       |       24 | WN424           | Miami            | Chicago            | 2025-10-15 16:50:00        | 2025-10-16 11:50:00        | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |       25 | B6525           | Los Angeles      | Denver             | 2025-11-01 09:20:00        | 2025-11-02 01:20:00        | Cabin  | Journeyman  |
|     35 | Cameron      | Cortes      |       25 | B6525           | Los Angeles      | Denver             | 2025-11-01 09:20:00        | 2025-11-02 01:20:00        | Cabin  | Trainee     |
|     45 | Logan        | Reyes       |       25 | B6525           | Los Angeles      | Denver             | 2025-11-01 09:20:00        | 2025-11-02 01:20:00        | Cabin  | Senior      |
|     15 | Steve        | Sanchez     |       25 | B6525           | Los Angeles      | Denver             | 2025-11-01 09:20:00        | 2025-11-02 01:20:00        | Pilot  | Trainee     |
|      5 | David        | Wilson      |       25 | B6525           | Los Angeles      | Denver             | 2025-11-01 09:20:00        | 2025-11-02 01:20:00        | Pilot  | Journeyman  |
|     46 | Ava          | Cruz        |       26 | AS626           | New York         | Seattle            | 2024-01-20 08:05:00        | 2024-01-20 12:45:00        | Cabin  | Journeyman  |
|     26 | Justin       | Ramos       |       26 | AS626           | New York         | Seattle            | 2024-01-20 08:05:00        | 2024-01-20 12:45:00        | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |       26 | AS626           | New York         | Seattle            | 2024-01-20 08:05:00        | 2024-01-20 12:45:00        | Cabin  | Senior      |
|      6 | Sarah        | Brown       |       26 | AS626           | New York         | Seattle            | 2024-01-20 08:05:00        | 2024-01-20 12:45:00        | Pilot  | Trainee     |
|     16 | Laura        | Ramirez     |       26 | AS626           | New York         | Seattle            | 2024-01-20 08:05:00        | 2024-01-20 12:45:00        | Pilot  | Senior      |
|     47 | Jackson      | Fernandez   |       27 | NK727           | Denver           | Miami              | 2024-02-25 10:35:00        | 2024-02-25 13:35:00        | Cabin  | Trainee     |
|     27 | Hannah       | Guzman      |       27 | NK727           | Denver           | Miami              | 2024-02-25 10:35:00        | 2024-02-25 13:35:00        | Cabin  | Senior      |
|     37 | Dylan        | Luna        |       27 | NK727           | Denver           | Miami              | 2024-02-25 10:35:00        | 2024-02-25 13:35:00        | Cabin  | Journeyman  |
|      7 | Chris        | Miller      |       27 | NK727           | Denver           | Miami              | 2024-02-25 10:35:00        | 2024-02-25 13:35:00        | Pilot  | Senior      |
|     17 | Kevin        | Torres      |       27 | NK727           | Denver           | Miami              | 2024-02-25 10:35:00        | 2024-02-25 13:35:00        | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |       28 | F9828           | Boston           | San Francisco      | 2024-03-15 14:10:00        | 2024-03-15 17:30:00        | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |       28 | F9828           | Boston           | San Francisco      | 2024-03-15 14:10:00        | 2024-03-15 17:30:00        | Cabin  | Trainee     |
|     48 | Mia          | Ruiz        |       28 | F9828           | Boston           | San Francisco      | 2024-03-15 14:10:00        | 2024-03-15 17:30:00        | Cabin  | Senior      |
|     18 | Jessica      | Flores      |       28 | F9828           | Boston           | San Francisco      | 2024-03-15 14:10:00        | 2024-03-15 17:30:00        | Pilot  | Trainee     |
|      8 | Anna         | Garcia      |       28 | F9828           | Boston           | San Francisco      | 2024-03-15 14:10:00        | 2024-03-15 17:30:00        | Pilot  | Journeyman  |
|     49 | Liam         | Alvarez     |       29 | G4929           | Dallas           | Los Angeles        | 2024-04-10 16:50:00        | 2024-04-10 21:50:00        | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |       29 | G4929           | Dallas           | Los Angeles        | 2024-04-10 16:50:00        | 2024-04-10 21:50:00        | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |       29 | G4929           | Dallas           | Los Angeles        | 2024-04-10 16:50:00        | 2024-04-10 21:50:00        | Cabin  | Trainee     |
|     19 | Brian        | Rivera      |       29 | G4929           | Dallas           | Los Angeles        | 2024-04-10 16:50:00        | 2024-04-10 21:50:00        | Pilot  | Senior      |
|      9 | Tom          | Rodriguez   |       29 | G4929           | Dallas           | Los Angeles        | 2024-04-10 16:50:00        | 2024-04-10 21:50:00        | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       30 | HA1030          | Burlington       | Seattle            | 2024-05-17 09:20:00        | 2024-05-17 13:00:00        | Cabin  | Journeyman  |
|     50 | Charlotte    | Morales     |       30 | HA1030          | Burlington       | Seattle            | 2024-05-17 09:20:00        | 2024-05-17 13:00:00        | Cabin  | Trainee     |
|     30 | Austin       | Moreno      |       30 | HA1030          | Burlington       | Seattle            | 2024-05-17 09:20:00        | 2024-05-17 13:00:00        | Cabin  | Senior      |
|     20 | Amanda       | Gomez       |       30 | HA1030          | Burlington       | Seattle            | 2024-05-17 09:20:00        | 2024-05-17 13:00:00        | Pilot  | Journeyman  |
|     10 | Lisa         | Martinez    |       30 | HA1030          | Burlington       | Seattle            | 2024-05-17 09:20:00        | 2024-05-17 13:00:00        | Pilot  | Senior      |
|     21 | Nicole       | Diaz        |       31 | AA131           | Chicago          | Boston             | 2024-06-23 11:05:00        | 2024-06-23 13:05:00        | Cabin  | Senior      |
|     41 | Nathan       | Soto        |       31 | AA131           | Chicago          | Boston             | 2024-06-23 11:05:00        | 2024-06-23 13:05:00        | Cabin  | Trainee     |
|     31 | Taylor       | Vargas      |       31 | AA131           | Chicago          | Boston             | 2024-06-23 11:05:00        | 2024-06-23 13:05:00        | Cabin  | Journeyman  |
|      1 | John         | Doe         |       31 | AA131           | Chicago          | Boston             | 2024-06-23 11:05:00        | 2024-06-23 13:05:00        | Pilot  | Senior      |
|     11 | Paul         | Hernandez   |       31 | AA131           | Chicago          | Boston             | 2024-06-23 11:05:00        | 2024-06-23 13:05:00        | Pilot  | Journeyman  |
|     42 | Isabella     | Mendoza     |       32 | DL232           | New York         | Dallas             | 2024-07-27 13:35:00        | 2024-07-27 18:25:00        | Cabin  | Senior      |
|     22 | Daniel       | Morales     |       32 | DL232           | New York         | Dallas             | 2024-07-27 13:35:00        | 2024-07-27 18:25:00        | Cabin  | Journeyman  |
|     32 | Madison      | Romero      |       32 | DL232           | New York         | Dallas             | 2024-07-27 13:35:00        | 2024-07-27 18:25:00        | Cabin  | Trainee     |
|     12 | Karen        | Lopez       |       32 | DL232           | New York         | Dallas             | 2024-07-27 13:35:00        | 2024-07-27 18:25:00        | Pilot  | Trainee     |
|      2 | Jane         | Smith       |       32 | DL232           | New York         | Dallas             | 2024-07-27 13:35:00        | 2024-07-27 18:25:00        | Pilot  | Journeyman  |
|     33 | Jordan       | Herrera     |       33 | UA333           | Miami            | Burlington         | 2024-08-19 15:25:00        | 2024-08-19 17:05:00        | Cabin  | Senior      |
|     23 | Ashley       | Ortiz       |       33 | UA333           | Miami            | Burlington         | 2024-08-19 15:25:00        | 2024-08-19 17:05:00        | Cabin  | Trainee     |
|     43 | Mason        | Silva       |       33 | UA333           | Miami            | Burlington         | 2024-08-19 15:25:00        | 2024-08-19 17:05:00        | Cabin  | Journeyman  |
|     13 | Mark         | Gonzalez    |       33 | UA333           | Miami            | Burlington         | 2024-08-19 15:25:00        | 2024-08-19 17:05:00        | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       33 | UA333           | Miami            | Burlington         | 2024-08-19 15:25:00        | 2024-08-19 17:05:00        | Pilot  | Trainee     |
|     24 | Tyler        | Gutierrez   |       34 | WN434           | Los Angeles      | Chicago            | 2024-09-14 17:05:00        | 2024-09-14 22:25:00        | Cabin  | Senior      |
|     34 | Alexis       | Medina      |       34 | WN434           | Los Angeles      | Chicago            | 2024-09-14 17:05:00        | 2024-09-14 22:25:00        | Cabin  | Journeyman  |
|     44 | Sophia       | Pena        |       34 | WN434           | Los Angeles      | Chicago            | 2024-09-14 17:05:00        | 2024-09-14 22:25:00        | Cabin  | Trainee     |
|      4 | Emily        | Davis       |       34 | WN434           | Los Angeles      | Chicago            | 2024-09-14 17:05:00        | 2024-09-14 22:25:00        | Pilot  | Senior      |
|     14 | Rachel       | Perez       |       34 | WN434           | Los Angeles      | Chicago            | 2024-09-14 17:05:00        | 2024-09-14 22:25:00        | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |       35 | B6535           | San Francisco    | Denver             | 2024-10-06 07:50:00        | 2024-10-06 12:20:00        | Cabin  | Journeyman  |
|     35 | Cameron      | Cortes      |       35 | B6535           | San Francisco    | Denver             | 2024-10-06 07:50:00        | 2024-10-06 12:20:00        | Cabin  | Trainee     |
|     45 | Logan        | Reyes       |       35 | B6535           | San Francisco    | Denver             | 2024-10-06 07:50:00        | 2024-10-06 12:20:00        | Cabin  | Senior      |
|     15 | Steve        | Sanchez     |       35 | B6535           | San Francisco    | Denver             | 2024-10-06 07:50:00        | 2024-10-06 12:20:00        | Pilot  | Trainee     |
|      5 | David        | Wilson      |       35 | B6535           | San Francisco    | Denver             | 2024-10-06 07:50:00        | 2024-10-06 12:20:00        | Pilot  | Journeyman  |
|     46 | Ava          | Cruz        |       36 | AS636           | Seattle          | Burlington         | 2024-01-25 08:05:00        | 2024-01-25 11:35:00        | Cabin  | Journeyman  |
|     26 | Justin       | Ramos       |       36 | AS636           | Seattle          | Burlington         | 2024-01-25 08:05:00        | 2024-01-25 11:35:00        | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |       36 | AS636           | Seattle          | Burlington         | 2024-01-25 08:05:00        | 2024-01-25 11:35:00        | Cabin  | Senior      |
|      6 | Sarah        | Brown       |       36 | AS636           | Seattle          | Burlington         | 2024-01-25 08:05:00        | 2024-01-25 11:35:00        | Pilot  | Trainee     |
|     16 | Laura        | Ramirez     |       36 | AS636           | Seattle          | Burlington         | 2024-01-25 08:05:00        | 2024-01-25 11:35:00        | Pilot  | Senior      |
|     47 | Jackson      | Fernandez   |       37 | NK737           | Boston           | Dallas             | 2024-02-28 10:35:00        | 2024-02-28 13:05:00        | Cabin  | Trainee     |
|     27 | Hannah       | Guzman      |       37 | NK737           | Boston           | Dallas             | 2024-02-28 10:35:00        | 2024-02-28 13:05:00        | Cabin  | Senior      |
|     37 | Dylan        | Luna        |       37 | NK737           | Boston           | Dallas             | 2024-02-28 10:35:00        | 2024-02-28 13:05:00        | Cabin  | Journeyman  |
|      7 | Chris        | Miller      |       37 | NK737           | Boston           | Dallas             | 2024-02-28 10:35:00        | 2024-02-28 13:05:00        | Pilot  | Senior      |
|     17 | Kevin        | Torres      |       37 | NK737           | Boston           | Dallas             | 2024-02-28 10:35:00        | 2024-02-28 13:05:00        | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |       38 | F9838           | San Francisco    | Miami              | 2024-03-20 14:10:00        | 2024-03-20 17:00:00        | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |       38 | F9838           | San Francisco    | Miami              | 2024-03-20 14:10:00        | 2024-03-20 17:00:00        | Cabin  | Trainee     |
|     48 | Mia          | Ruiz        |       38 | F9838           | San Francisco    | Miami              | 2024-03-20 14:10:00        | 2024-03-20 17:00:00        | Cabin  | Senior      |
|     18 | Jessica      | Flores      |       38 | F9838           | San Francisco    | Miami              | 2024-03-20 14:10:00        | 2024-03-20 17:00:00        | Pilot  | Trainee     |
|      8 | Anna         | Garcia      |       38 | F9838           | San Francisco    | Miami              | 2024-03-20 14:10:00        | 2024-03-20 17:00:00        | Pilot  | Journeyman  |
|     49 | Liam         | Alvarez     |       39 | G4939           | New York         | Boston             | 2024-04-15 16:50:00        | 2024-04-15 20:10:00        | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |       39 | G4939           | New York         | Boston             | 2024-04-15 16:50:00        | 2024-04-15 20:10:00        | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |       39 | G4939           | New York         | Boston             | 2024-04-15 16:50:00        | 2024-04-15 20:10:00        | Cabin  | Trainee     |
|     19 | Brian        | Rivera      |       39 | G4939           | New York         | Boston             | 2024-04-15 16:50:00        | 2024-04-15 20:10:00        | Pilot  | Senior      |
|      9 | Tom          | Rodriguez   |       39 | G4939           | New York         | Boston             | 2024-04-15 16:50:00        | 2024-04-15 20:10:00        | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       40 | HA1040          | Chicago          | San Francisco      | 2024-05-22 09:20:00        | 2024-05-22 14:30:00        | Cabin  | Journeyman  |
|     50 | Charlotte    | Morales     |       40 | HA1040          | Chicago          | San Francisco      | 2024-05-22 09:20:00        | 2024-05-22 14:30:00        | Cabin  | Trainee     |
|     30 | Austin       | Moreno      |       40 | HA1040          | Chicago          | San Francisco      | 2024-05-22 09:20:00        | 2024-05-22 14:30:00        | Cabin  | Senior      |
|     20 | Amanda       | Gomez       |       40 | HA1040          | Chicago          | San Francisco      | 2024-05-22 09:20:00        | 2024-05-22 14:30:00        | Pilot  | Journeyman  |
|     10 | Lisa         | Martinez    |       40 | HA1040          | Chicago          | San Francisco      | 2024-05-22 09:20:00        | 2024-05-22 14:30:00        | Pilot  | Senior      |
|     21 | Nicole       | Diaz        |       41 | AA501           | New York         | Chicago            | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Senior      |
|     22 | Daniel       | Morales     |       41 | AA501           | New York         | Chicago            | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Journeyman  |
|     23 | Ashley       | Ortiz       |       41 | AA501           | New York         | Chicago            | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Trainee     |
|      1 | John         | Doe         |       41 | AA501           | New York         | Chicago            | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Pilot  | Senior      |
|      2 | Jane         | Smith       |       41 | AA501           | New York         | Chicago            | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |       42 | DL502           | New York         | Los Angeles        | 2025-11-08 08:59:28.883333 | 2025-11-08 12:59:28.883333 | Cabin  | Journeyman  |
|     24 | Tyler        | Gutierrez   |       42 | DL502           | New York         | Los Angeles        | 2025-11-08 08:59:28.883333 | 2025-11-08 12:59:28.883333 | Cabin  | Senior      |
|     26 | Justin       | Ramos       |       42 | DL502           | New York         | Los Angeles        | 2025-11-08 08:59:28.883333 | 2025-11-08 12:59:28.883333 | Cabin  | Trainee     |
|      1 | John         | Doe         |       42 | DL502           | New York         | Los Angeles        | 2025-11-08 08:59:28.883333 | 2025-11-08 12:59:28.883333 | Pilot  | Senior      |
|      2 | Jane         | Smith       |       42 | DL502           | New York         | Los Angeles        | 2025-11-08 08:59:28.883333 | 2025-11-08 12:59:28.883333 | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |       43 | UA503           | New York         | Miami              | 2025-11-08 18:59:28.883333 | 2025-11-08 23:59:28.883333 | Cabin  | Journeyman  |
|     27 | Hannah       | Guzman      |       43 | UA503           | New York         | Miami              | 2025-11-08 18:59:28.883333 | 2025-11-08 23:59:28.883333 | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |       43 | UA503           | New York         | Miami              | 2025-11-08 18:59:28.883333 | 2025-11-08 23:59:28.883333 | Cabin  | Trainee     |
|      1 | John         | Doe         |       43 | UA503           | New York         | Miami              | 2025-11-08 18:59:28.883333 | 2025-11-08 23:59:28.883333 | Pilot  | Senior      |
|      2 | Jane         | Smith       |       43 | UA503           | New York         | Miami              | 2025-11-08 18:59:28.883333 | 2025-11-08 23:59:28.883333 | Pilot  | Journeyman  |
|     30 | Austin       | Moreno      |       44 | WN504           | New York         | Seattle            | 2025-11-09 04:59:28.883333 | 2025-11-09 10:59:28.883333 | Cabin  | Senior      |
|     32 | Madison      | Romero      |       44 | WN504           | New York         | Seattle            | 2025-11-09 04:59:28.883333 | 2025-11-09 10:59:28.883333 | Cabin  | Trainee     |
|     31 | Taylor       | Vargas      |       44 | WN504           | New York         | Seattle            | 2025-11-09 04:59:28.883333 | 2025-11-09 10:59:28.883333 | Cabin  | Journeyman  |
|      1 | John         | Doe         |       44 | WN504           | New York         | Seattle            | 2025-11-09 04:59:28.883333 | 2025-11-09 10:59:28.883333 | Pilot  | Senior      |
|      2 | Jane         | Smith       |       44 | WN504           | New York         | Seattle            | 2025-11-09 04:59:28.883333 | 2025-11-09 10:59:28.883333 | Pilot  | Journeyman  |
|     35 | Cameron      | Cortes      |       45 | B6601           | Burlington       | Chicago            | 2025-11-03 08:59:28.883333 | 2025-11-03 15:59:28.883333 | Cabin  | Trainee     |
|     33 | Jordan       | Herrera     |       45 | B6601           | Burlington       | Chicago            | 2025-11-03 08:59:28.883333 | 2025-11-03 15:59:28.883333 | Cabin  | Senior      |
|     34 | Alexis       | Medina      |       45 | B6601           | Burlington       | Chicago            | 2025-11-03 08:59:28.883333 | 2025-11-03 15:59:28.883333 | Cabin  | Journeyman  |
|      4 | Emily        | Davis       |       45 | B6601           | Burlington       | Chicago            | 2025-11-03 08:59:28.883333 | 2025-11-03 15:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       45 | B6601           | Burlington       | Chicago            | 2025-11-03 08:59:28.883333 | 2025-11-03 15:59:28.883333 | Pilot  | Trainee     |
|     37 | Dylan        | Luna        |       46 | AS602           | Burlington       | Los Angeles        | 2025-11-03 18:59:28.883333 | 2025-11-04 02:59:28.883333 | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |       46 | AS602           | Burlington       | Los Angeles        | 2025-11-03 18:59:28.883333 | 2025-11-04 02:59:28.883333 | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |       46 | AS602           | Burlington       | Los Angeles        | 2025-11-03 18:59:28.883333 | 2025-11-04 02:59:28.883333 | Cabin  | Senior      |
|      4 | Emily        | Davis       |       46 | AS602           | Burlington       | Los Angeles        | 2025-11-03 18:59:28.883333 | 2025-11-04 02:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       46 | AS602           | Burlington       | Los Angeles        | 2025-11-03 18:59:28.883333 | 2025-11-04 02:59:28.883333 | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       47 | NK603           | Burlington       | Miami              | 2025-11-04 14:59:28.883333 | 2025-11-04 21:59:28.883333 | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |       47 | NK603           | Burlington       | Miami              | 2025-11-04 14:59:28.883333 | 2025-11-04 21:59:28.883333 | Cabin  | Senior      |
|     41 | Nathan       | Soto        |       47 | NK603           | Burlington       | Miami              | 2025-11-04 14:59:28.883333 | 2025-11-04 21:59:28.883333 | Cabin  | Trainee     |
|      4 | Emily        | Davis       |       47 | NK603           | Burlington       | Miami              | 2025-11-04 14:59:28.883333 | 2025-11-04 21:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       47 | NK603           | Burlington       | Miami              | 2025-11-04 14:59:28.883333 | 2025-11-04 21:59:28.883333 | Pilot  | Trainee     |
|     42 | Isabella     | Mendoza     |       48 | F9604           | Burlington       | Seattle            | 2025-11-05 10:59:28.883333 | 2025-11-05 18:59:28.883333 | Cabin  | Senior      |
|     44 | Sophia       | Pena        |       48 | F9604           | Burlington       | Seattle            | 2025-11-05 10:59:28.883333 | 2025-11-05 18:59:28.883333 | Cabin  | Trainee     |
|     43 | Mason        | Silva       |       48 | F9604           | Burlington       | Seattle            | 2025-11-05 10:59:28.883333 | 2025-11-05 18:59:28.883333 | Cabin  | Journeyman  |
|      4 | Emily        | Davis       |       48 | F9604           | Burlington       | Seattle            | 2025-11-05 10:59:28.883333 | 2025-11-05 18:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       48 | F9604           | Burlington       | Seattle            | 2025-11-05 10:59:28.883333 | 2025-11-05 18:59:28.883333 | Pilot  | Trainee     |
|     46 | Ava          | Cruz        |       49 | G4605           | Burlington       | Denver             | 2025-11-06 06:59:28.883333 | 2025-11-06 15:59:28.883333 | Cabin  | Journeyman  |
|     47 | Jackson      | Fernandez   |       49 | G4605           | Burlington       | Denver             | 2025-11-06 06:59:28.883333 | 2025-11-06 15:59:28.883333 | Cabin  | Trainee     |
|     45 | Logan        | Reyes       |       49 | G4605           | Burlington       | Denver             | 2025-11-06 06:59:28.883333 | 2025-11-06 15:59:28.883333 | Cabin  | Senior      |
|      4 | Emily        | Davis       |       49 | G4605           | Burlington       | Denver             | 2025-11-06 06:59:28.883333 | 2025-11-06 15:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       49 | G4605           | Burlington       | Denver             | 2025-11-06 06:59:28.883333 | 2025-11-06 15:59:28.883333 | Pilot  | Trainee     |
|     49 | Liam         | Alvarez     |       50 | HA606           | Burlington       | Boston             | 2025-11-07 02:59:28.883333 | 2025-11-07 12:59:28.883333 | Cabin  | Journeyman  |
|     50 | Charlotte    | Morales     |       50 | HA606           | Burlington       | Boston             | 2025-11-07 02:59:28.883333 | 2025-11-07 12:59:28.883333 | Cabin  | Trainee     |
|     48 | Mia          | Ruiz        |       50 | HA606           | Burlington       | Boston             | 2025-11-07 02:59:28.883333 | 2025-11-07 12:59:28.883333 | Cabin  | Senior      |
|      4 | Emily        | Davis       |       50 | HA606           | Burlington       | Boston             | 2025-11-07 02:59:28.883333 | 2025-11-07 12:59:28.883333 | Pilot  | Senior      |
|      3 | Mike         | Johnson     |       50 | HA606           | Burlington       | Boston             | 2025-11-07 02:59:28.883333 | 2025-11-07 12:59:28.883333 | Pilot  | Trainee     |
|     21 | Nicole       | Diaz        |       51 | AA701           | Chicago          | Los Angeles        | 2025-10-15 14:59:28.883333 | 2025-10-15 20:59:28.883333 | Cabin  | Senior      |
|     22 | Daniel       | Morales     |       51 | AA701           | Chicago          | Los Angeles        | 2025-10-15 14:59:28.883333 | 2025-10-15 20:59:28.883333 | Cabin  | Journeyman  |
|     23 | Ashley       | Ortiz       |       51 | AA701           | Chicago          | Los Angeles        | 2025-10-15 14:59:28.883333 | 2025-10-15 20:59:28.883333 | Cabin  | Trainee     |
|      6 | Sarah        | Brown       |       51 | AA701           | Chicago          | Los Angeles        | 2025-10-15 14:59:28.883333 | 2025-10-15 20:59:28.883333 | Pilot  | Trainee     |
|      5 | David        | Wilson      |       51 | AA701           | Chicago          | Los Angeles        | 2025-10-15 14:59:28.883333 | 2025-10-15 20:59:28.883333 | Pilot  | Journeyman  |
|     25 | Megan        | Chavez      |       52 | DL702           | Chicago          | Miami              | 2025-10-17 16:59:28.883333 | 2025-10-17 23:59:28.883333 | Cabin  | Journeyman  |
|     24 | Tyler        | Gutierrez   |       52 | DL702           | Chicago          | Miami              | 2025-10-17 16:59:28.883333 | 2025-10-17 23:59:28.883333 | Cabin  | Senior      |
|     26 | Justin       | Ramos       |       52 | DL702           | Chicago          | Miami              | 2025-10-17 16:59:28.883333 | 2025-10-17 23:59:28.883333 | Cabin  | Trainee     |
|      6 | Sarah        | Brown       |       52 | DL702           | Chicago          | Miami              | 2025-10-17 16:59:28.883333 | 2025-10-17 23:59:28.883333 | Pilot  | Trainee     |
|      5 | David        | Wilson      |       52 | DL702           | Chicago          | Miami              | 2025-10-17 16:59:28.883333 | 2025-10-17 23:59:28.883333 | Pilot  | Journeyman  |
|     28 | Brandon      | Castillo    |       53 | UA703           | Chicago          | Seattle            | 2025-10-19 18:59:28.883333 | 2025-10-20 02:59:28.883333 | Cabin  | Journeyman  |
|     27 | Hannah       | Guzman      |       53 | UA703           | Chicago          | Seattle            | 2025-10-19 18:59:28.883333 | 2025-10-20 02:59:28.883333 | Cabin  | Senior      |
|     29 | Samantha     | Jimenez     |       53 | UA703           | Chicago          | Seattle            | 2025-10-19 18:59:28.883333 | 2025-10-20 02:59:28.883333 | Cabin  | Trainee     |
|      6 | Sarah        | Brown       |       53 | UA703           | Chicago          | Seattle            | 2025-10-19 18:59:28.883333 | 2025-10-20 02:59:28.883333 | Pilot  | Trainee     |
|      5 | David        | Wilson      |       53 | UA703           | Chicago          | Seattle            | 2025-10-19 18:59:28.883333 | 2025-10-20 02:59:28.883333 | Pilot  | Journeyman  |
|     30 | Austin       | Moreno      |       54 | WN801           | Los Angeles      | Miami              | 2025-11-01 06:59:28.883333 | 2025-11-01 21:29:28.883333 | Cabin  | Senior      |
|     32 | Madison      | Romero      |       54 | WN801           | Los Angeles      | Miami              | 2025-11-01 06:59:28.883333 | 2025-11-01 21:29:28.883333 | Cabin  | Trainee     |
|     31 | Taylor       | Vargas      |       54 | WN801           | Los Angeles      | Miami              | 2025-11-01 06:59:28.883333 | 2025-11-01 21:29:28.883333 | Cabin  | Journeyman  |
|      8 | Anna         | Garcia      |       54 | WN801           | Los Angeles      | Miami              | 2025-11-01 06:59:28.883333 | 2025-11-01 21:29:28.883333 | Pilot  | Journeyman  |
|      7 | Chris        | Miller      |       54 | WN801           | Los Angeles      | Miami              | 2025-11-01 06:59:28.883333 | 2025-11-01 21:29:28.883333 | Pilot  | Senior      |
|     35 | Cameron      | Cortes      |       55 | B6802           | Los Angeles      | Seattle            | 2025-11-02 02:59:28.883333 | 2025-11-02 23:59:28.883333 | Cabin  | Trainee     |
|     33 | Jordan       | Herrera     |       55 | B6802           | Los Angeles      | Seattle            | 2025-11-02 02:59:28.883333 | 2025-11-02 23:59:28.883333 | Cabin  | Senior      |
|     34 | Alexis       | Medina      |       55 | B6802           | Los Angeles      | Seattle            | 2025-11-02 02:59:28.883333 | 2025-11-02 23:59:28.883333 | Cabin  | Journeyman  |
|     10 | Lisa         | Martinez    |       55 | B6802           | Los Angeles      | Seattle            | 2025-11-02 02:59:28.883333 | 2025-11-02 23:59:28.883333 | Pilot  | Senior      |
|      9 | Tom          | Rodriguez   |       55 | B6802           | Los Angeles      | Seattle            | 2025-11-02 02:59:28.883333 | 2025-11-02 23:59:28.883333 | Pilot  | Trainee     |
|     37 | Dylan        | Luna        |       56 | AS901           | Miami            | Seattle            | 2025-11-07 12:59:28.883333 | 2025-11-07 16:59:28.883333 | Cabin  | Journeyman  |
|     38 | Hailey       | Ortega      |       56 | AS901           | Miami            | Seattle            | 2025-11-07 12:59:28.883333 | 2025-11-07 16:59:28.883333 | Cabin  | Trainee     |
|     36 | Kayla        | Santiago    |       56 | AS901           | Miami            | Seattle            | 2025-11-07 12:59:28.883333 | 2025-11-07 16:59:28.883333 | Cabin  | Senior      |
|     11 | Paul         | Hernandez   |       56 | AS901           | Miami            | Seattle            | 2025-11-07 12:59:28.883333 | 2025-11-07 16:59:28.883333 | Pilot  | Journeyman  |
|     12 | Karen        | Lopez       |       56 | AS901           | Miami            | Seattle            | 2025-11-07 12:59:28.883333 | 2025-11-07 16:59:28.883333 | Pilot  | Trainee     |
|     40 | Avery        | Castro      |       57 | NK902           | Miami            | Denver             | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Journeyman  |
|     39 | Ethan        | Delgado     |       57 | NK902           | Miami            | Denver             | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Senior      |
|     36 | Kayla        | Santiago    |       57 | NK902           | Miami            | Denver             | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Cabin  | Senior      |
|     11 | Paul         | Hernandez   |       57 | NK902           | Miami            | Denver             | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Pilot  | Journeyman  |
|     12 | Karen        | Lopez       |       57 | NK902           | Miami            | Denver             | 2025-11-08 00:59:28.883333 | 2025-11-08 03:59:28.883333 | Pilot  | Trainee     |

## Report 2: Crew exceeding hour limits

This report lists crew members who have exceeded or are at risk of exceeding their work hour limitations as per regulatory requirements.

No data available.

## Report 3: Monthly hours worked by crew

This report provides a summary of hours worked per month by each crew member to support payroll processing.

|   Crew | First Name   | Last Name   |   Year |   Month |   Monthly Hours | Seniority   |
|-------:|:-------------|:------------|-------:|--------:|----------------:|:------------|
|      1 | John         | Doe         |   2024 |       6 |            2    | Senior      |
|      1 | John         | Doe         |   2024 |      11 |            3.33 | Senior      |
|      1 | John         | Doe         |   2025 |       9 |           15    | Senior      |
|      1 | John         | Doe         |   2025 |      11 |           18    | Senior      |
|      2 | Jane         | Smith       |   2024 |       2 |            3    | Journeyman  |
|      2 | Jane         | Smith       |   2024 |       7 |            4.83 | Journeyman  |
|      2 | Jane         | Smith       |   2024 |      12 |            4    | Journeyman  |
|      2 | Jane         | Smith       |   2025 |       9 |           18    | Journeyman  |
|      2 | Jane         | Smith       |   2025 |      11 |           18    | Journeyman  |
|      3 | Mike         | Johnson     |   2024 |       3 |            2.5  | Trainee     |
|      3 | Mike         | Johnson     |   2024 |       8 |            1.67 | Trainee     |
|      3 | Mike         | Johnson     |   2025 |       1 |            5.33 | Trainee     |
|      3 | Mike         | Johnson     |   2025 |      10 |           12    | Trainee     |
|      3 | Mike         | Johnson     |   2025 |      11 |           49    | Trainee     |
|      4 | Emily        | Davis       |   2024 |       4 |            1.5  | Senior      |
|      4 | Emily        | Davis       |   2024 |       9 |            5.33 | Senior      |
|      4 | Emily        | Davis       |   2024 |      11 |            3.33 | Senior      |
|      4 | Emily        | Davis       |   2025 |       2 |            2.67 | Senior      |
|      4 | Emily        | Davis       |   2025 |      10 |           19    | Senior      |
|      4 | Emily        | Davis       |   2025 |      11 |           49    | Senior      |
|      5 | David        | Wilson      |   2024 |       5 |            5    | Journeyman  |
|      5 | David        | Wilson      |   2024 |      10 |            4.5  | Journeyman  |
|      5 | David        | Wilson      |   2025 |       3 |            4.17 | Journeyman  |
|      5 | David        | Wilson      |   2025 |      10 |           21    | Journeyman  |
|      5 | David        | Wilson      |   2025 |      11 |           16    | Journeyman  |
|      6 | Sarah        | Brown       |   2024 |       1 |            8.17 | Trainee     |
|      6 | Sarah        | Brown       |   2024 |       6 |            4.17 | Trainee     |
|      6 | Sarah        | Brown       |   2025 |       4 |            2.17 | Trainee     |
|      6 | Sarah        | Brown       |   2025 |      10 |           21    | Trainee     |
|      7 | Chris        | Miller      |   2024 |       2 |            5.5  | Senior      |
|      7 | Chris        | Miller      |   2024 |       7 |            2.33 | Senior      |
|      7 | Chris        | Miller      |   2025 |       5 |            4.67 | Senior      |
|      7 | Chris        | Miller      |   2025 |      11 |           14.5  | Senior      |
|      8 | Anna         | Garcia      |   2024 |       3 |            6.17 | Journeyman  |
|      8 | Anna         | Garcia      |   2024 |       8 |            2.67 | Journeyman  |
|      8 | Anna         | Garcia      |   2025 |       6 |            2.5  | Journeyman  |
|      8 | Anna         | Garcia      |   2025 |      11 |           14.5  | Journeyman  |
|      9 | Tom          | Rodriguez   |   2024 |       4 |            8.33 | Trainee     |
|      9 | Tom          | Rodriguez   |   2024 |       9 |            1.83 | Trainee     |
|      9 | Tom          | Rodriguez   |   2025 |       7 |            5    | Trainee     |
|      9 | Tom          | Rodriguez   |   2025 |      11 |           21    | Trainee     |
|     10 | Lisa         | Martinez    |   2024 |       5 |            8.83 | Senior      |
|     10 | Lisa         | Martinez    |   2024 |      10 |            1.67 | Senior      |
|     10 | Lisa         | Martinez    |   2025 |       8 |            2.83 | Senior      |
|     10 | Lisa         | Martinez    |   2025 |      11 |           21    | Senior      |
|     11 | Paul         | Hernandez   |   2024 |       6 |            2    | Journeyman  |
|     11 | Paul         | Hernandez   |   2024 |      11 |            3.33 | Journeyman  |
|     11 | Paul         | Hernandez   |   2025 |       9 |           15    | Journeyman  |
|     11 | Paul         | Hernandez   |   2025 |      11 |            7    | Journeyman  |
|     12 | Karen        | Lopez       |   2024 |       2 |            3    | Trainee     |
|     12 | Karen        | Lopez       |   2024 |       7 |            4.83 | Trainee     |
|     12 | Karen        | Lopez       |   2024 |      12 |            4    | Trainee     |
|     12 | Karen        | Lopez       |   2025 |       9 |           18    | Trainee     |
|     12 | Karen        | Lopez       |   2025 |      11 |            7    | Trainee     |
|     13 | Mark         | Gonzalez    |   2024 |       3 |            2.5  | Senior      |
|     13 | Mark         | Gonzalez    |   2024 |       8 |            1.67 | Senior      |
|     13 | Mark         | Gonzalez    |   2025 |       1 |            5.33 | Senior      |
|     13 | Mark         | Gonzalez    |   2025 |      10 |           12    | Senior      |
|     14 | Rachel       | Perez       |   2024 |       4 |            1.5  | Journeyman  |
|     14 | Rachel       | Perez       |   2024 |       9 |            5.33 | Journeyman  |
|     14 | Rachel       | Perez       |   2025 |       2 |            2.67 | Journeyman  |
|     14 | Rachel       | Perez       |   2025 |      10 |           19    | Journeyman  |
|     15 | Steve        | Sanchez     |   2024 |       5 |            5    | Trainee     |
|     15 | Steve        | Sanchez     |   2024 |      10 |            4.5  | Trainee     |
|     15 | Steve        | Sanchez     |   2025 |       3 |            4.17 | Trainee     |
|     15 | Steve        | Sanchez     |   2025 |      11 |           16    | Trainee     |
|     16 | Laura        | Ramirez     |   2024 |       1 |            8.17 | Senior      |
|     16 | Laura        | Ramirez     |   2024 |       6 |            4.17 | Senior      |
|     16 | Laura        | Ramirez     |   2025 |       4 |            2.17 | Senior      |
|     17 | Kevin        | Torres      |   2024 |       2 |            5.5  | Journeyman  |
|     17 | Kevin        | Torres      |   2024 |       7 |            2.33 | Journeyman  |
|     17 | Kevin        | Torres      |   2025 |       5 |            4.67 | Journeyman  |
|     18 | Jessica      | Flores      |   2024 |       3 |            6.17 | Trainee     |
|     18 | Jessica      | Flores      |   2024 |       8 |            2.67 | Trainee     |
|     18 | Jessica      | Flores      |   2025 |       6 |            2.5  | Trainee     |
|     19 | Brian        | Rivera      |   2024 |       4 |            8.33 | Senior      |
|     19 | Brian        | Rivera      |   2024 |       9 |            1.83 | Senior      |
|     19 | Brian        | Rivera      |   2025 |       7 |            5    | Senior      |
|     20 | Amanda       | Gomez       |   2024 |       5 |            8.83 | Journeyman  |
|     20 | Amanda       | Gomez       |   2024 |      10 |            1.67 | Journeyman  |
|     20 | Amanda       | Gomez       |   2025 |       8 |            2.83 | Journeyman  |
|     21 | Nicole       | Diaz        |   2024 |       6 |            2    | Senior      |
|     21 | Nicole       | Diaz        |   2024 |      11 |            3.33 | Senior      |
|     21 | Nicole       | Diaz        |   2025 |       9 |           15    | Senior      |
|     21 | Nicole       | Diaz        |   2025 |      10 |            6    | Senior      |
|     21 | Nicole       | Diaz        |   2025 |      11 |            3    | Senior      |
|     22 | Daniel       | Morales     |   2024 |       2 |            3    | Journeyman  |
|     22 | Daniel       | Morales     |   2024 |       7 |            4.83 | Journeyman  |
|     22 | Daniel       | Morales     |   2024 |      12 |            4    | Journeyman  |
|     22 | Daniel       | Morales     |   2025 |       9 |           18    | Journeyman  |
|     22 | Daniel       | Morales     |   2025 |      10 |            6    | Journeyman  |
|     22 | Daniel       | Morales     |   2025 |      11 |            3    | Journeyman  |
|     23 | Ashley       | Ortiz       |   2024 |       3 |            2.5  | Trainee     |
|     23 | Ashley       | Ortiz       |   2024 |       8 |            1.67 | Trainee     |
|     23 | Ashley       | Ortiz       |   2025 |       1 |            5.33 | Trainee     |
|     23 | Ashley       | Ortiz       |   2025 |      10 |           18    | Trainee     |
|     23 | Ashley       | Ortiz       |   2025 |      11 |            3    | Trainee     |
|     24 | Tyler        | Gutierrez   |   2024 |       4 |            1.5  | Senior      |
|     24 | Tyler        | Gutierrez   |   2024 |       9 |            5.33 | Senior      |
|     24 | Tyler        | Gutierrez   |   2025 |       2 |            2.67 | Senior      |
|     24 | Tyler        | Gutierrez   |   2025 |      10 |           26    | Senior      |
|     24 | Tyler        | Gutierrez   |   2025 |      11 |            4    | Senior      |
|     25 | Megan        | Chavez      |   2024 |       5 |            5    | Journeyman  |
|     25 | Megan        | Chavez      |   2024 |      10 |            4.5  | Journeyman  |
|     25 | Megan        | Chavez      |   2025 |       3 |            4.17 | Journeyman  |
|     25 | Megan        | Chavez      |   2025 |      10 |            7    | Journeyman  |
|     25 | Megan        | Chavez      |   2025 |      11 |           20    | Journeyman  |
|     26 | Justin       | Ramos       |   2024 |       1 |            8.17 | Trainee     |
|     26 | Justin       | Ramos       |   2024 |       6 |            4.17 | Trainee     |
|     26 | Justin       | Ramos       |   2025 |       4 |            2.17 | Trainee     |
|     26 | Justin       | Ramos       |   2025 |      10 |            7    | Trainee     |
|     26 | Justin       | Ramos       |   2025 |      11 |            4    | Trainee     |
|     27 | Hannah       | Guzman      |   2024 |       2 |            5.5  | Senior      |
|     27 | Hannah       | Guzman      |   2024 |       7 |            2.33 | Senior      |
|     27 | Hannah       | Guzman      |   2025 |       5 |            4.67 | Senior      |
|     27 | Hannah       | Guzman      |   2025 |      10 |            8    | Senior      |
|     27 | Hannah       | Guzman      |   2025 |      11 |            5    | Senior      |
|     28 | Brandon      | Castillo    |   2024 |       3 |            6.17 | Journeyman  |
|     28 | Brandon      | Castillo    |   2024 |       8 |            2.67 | Journeyman  |
|     28 | Brandon      | Castillo    |   2025 |       6 |            2.5  | Journeyman  |
|     28 | Brandon      | Castillo    |   2025 |      10 |            8    | Journeyman  |
|     28 | Brandon      | Castillo    |   2025 |      11 |            5    | Journeyman  |
|     29 | Samantha     | Jimenez     |   2024 |       4 |            8.33 | Trainee     |
|     29 | Samantha     | Jimenez     |   2024 |       9 |            1.83 | Trainee     |
|     29 | Samantha     | Jimenez     |   2025 |       7 |            5    | Trainee     |
|     29 | Samantha     | Jimenez     |   2025 |      10 |            8    | Trainee     |
|     29 | Samantha     | Jimenez     |   2025 |      11 |            5    | Trainee     |
|     30 | Austin       | Moreno      |   2024 |       5 |            8.83 | Senior      |
|     30 | Austin       | Moreno      |   2024 |      10 |            1.67 | Senior      |
|     30 | Austin       | Moreno      |   2025 |       8 |            2.83 | Senior      |
|     30 | Austin       | Moreno      |   2025 |      11 |           20.5  | Senior      |
|     31 | Taylor       | Vargas      |   2024 |       6 |            2    | Journeyman  |
|     31 | Taylor       | Vargas      |   2024 |      11 |            3.33 | Journeyman  |
|     31 | Taylor       | Vargas      |   2025 |       9 |           15    | Journeyman  |
|     31 | Taylor       | Vargas      |   2025 |      11 |           20.5  | Journeyman  |
|     32 | Madison      | Romero      |   2024 |       2 |            3    | Trainee     |
|     32 | Madison      | Romero      |   2024 |       7 |            4.83 | Trainee     |
|     32 | Madison      | Romero      |   2024 |      12 |            4    | Trainee     |
|     32 | Madison      | Romero      |   2025 |       9 |           18    | Trainee     |
|     32 | Madison      | Romero      |   2025 |      11 |           20.5  | Trainee     |
|     33 | Jordan       | Herrera     |   2024 |       3 |            2.5  | Senior      |
|     33 | Jordan       | Herrera     |   2024 |       8 |            1.67 | Senior      |
|     33 | Jordan       | Herrera     |   2025 |       1 |            5.33 | Senior      |
|     33 | Jordan       | Herrera     |   2025 |      10 |           12    | Senior      |
|     33 | Jordan       | Herrera     |   2025 |      11 |           28    | Senior      |
|     34 | Alexis       | Medina      |   2024 |       4 |            1.5  | Journeyman  |
|     34 | Alexis       | Medina      |   2024 |       9 |            5.33 | Journeyman  |
|     34 | Alexis       | Medina      |   2025 |       2 |            2.67 | Journeyman  |
|     34 | Alexis       | Medina      |   2025 |      10 |           19    | Journeyman  |
|     34 | Alexis       | Medina      |   2025 |      11 |           28    | Journeyman  |
|     35 | Cameron      | Cortes      |   2024 |       5 |            5    | Trainee     |
|     35 | Cameron      | Cortes      |   2024 |      10 |            4.5  | Trainee     |
|     35 | Cameron      | Cortes      |   2025 |       3 |            4.17 | Trainee     |
|     35 | Cameron      | Cortes      |   2025 |      11 |           44    | Trainee     |
|     36 | Kayla        | Santiago    |   2024 |       1 |            8.17 | Senior      |
|     36 | Kayla        | Santiago    |   2024 |       6 |            4.17 | Senior      |
|     36 | Kayla        | Santiago    |   2025 |       4 |            2.17 | Senior      |
|     36 | Kayla        | Santiago    |   2025 |      11 |           15    | Senior      |
|     37 | Dylan        | Luna        |   2024 |       2 |            5.5  | Journeyman  |
|     37 | Dylan        | Luna        |   2024 |       7 |            2.33 | Journeyman  |
|     37 | Dylan        | Luna        |   2025 |       5 |            4.67 | Journeyman  |
|     37 | Dylan        | Luna        |   2025 |      11 |           12    | Journeyman  |
|     38 | Hailey       | Ortega      |   2024 |       3 |            6.17 | Trainee     |
|     38 | Hailey       | Ortega      |   2024 |       8 |            2.67 | Trainee     |
|     38 | Hailey       | Ortega      |   2025 |       6 |            2.5  | Trainee     |
|     38 | Hailey       | Ortega      |   2025 |      11 |           12    | Trainee     |
|     39 | Ethan        | Delgado     |   2024 |       4 |            8.33 | Senior      |
|     39 | Ethan        | Delgado     |   2024 |       9 |            1.83 | Senior      |
|     39 | Ethan        | Delgado     |   2025 |       7 |            5    | Senior      |
|     39 | Ethan        | Delgado     |   2025 |      11 |           10    | Senior      |
|     40 | Avery        | Castro      |   2024 |       5 |            8.83 | Journeyman  |
|     40 | Avery        | Castro      |   2024 |      10 |            1.67 | Journeyman  |
|     40 | Avery        | Castro      |   2025 |       8 |            2.83 | Journeyman  |
|     40 | Avery        | Castro      |   2025 |      11 |           10    | Journeyman  |
|     41 | Nathan       | Soto        |   2024 |       6 |            2    | Trainee     |
|     41 | Nathan       | Soto        |   2024 |      11 |            3.33 | Trainee     |
|     41 | Nathan       | Soto        |   2025 |       9 |           15    | Trainee     |
|     41 | Nathan       | Soto        |   2025 |      11 |            7    | Trainee     |
|     42 | Isabella     | Mendoza     |   2024 |       2 |            3    | Senior      |
|     42 | Isabella     | Mendoza     |   2024 |       7 |            4.83 | Senior      |
|     42 | Isabella     | Mendoza     |   2024 |      12 |            4    | Senior      |
|     42 | Isabella     | Mendoza     |   2025 |       9 |           18    | Senior      |
|     42 | Isabella     | Mendoza     |   2025 |      11 |            8    | Senior      |
|     43 | Mason        | Silva       |   2024 |       3 |            2.5  | Journeyman  |
|     43 | Mason        | Silva       |   2024 |       8 |            1.67 | Journeyman  |
|     43 | Mason        | Silva       |   2025 |       1 |            5.33 | Journeyman  |
|     43 | Mason        | Silva       |   2025 |      10 |           12    | Journeyman  |
|     43 | Mason        | Silva       |   2025 |      11 |            8    | Journeyman  |
|     44 | Sophia       | Pena        |   2024 |       4 |            1.5  | Trainee     |
|     44 | Sophia       | Pena        |   2024 |       9 |            5.33 | Trainee     |
|     44 | Sophia       | Pena        |   2025 |       2 |            2.67 | Trainee     |
|     44 | Sophia       | Pena        |   2025 |      10 |           19    | Trainee     |
|     44 | Sophia       | Pena        |   2025 |      11 |            8    | Trainee     |
|     45 | Logan        | Reyes       |   2024 |       5 |            5    | Senior      |
|     45 | Logan        | Reyes       |   2024 |      10 |            4.5  | Senior      |
|     45 | Logan        | Reyes       |   2025 |       3 |            4.17 | Senior      |
|     45 | Logan        | Reyes       |   2025 |      11 |           25    | Senior      |
|     46 | Ava          | Cruz        |   2024 |       1 |            8.17 | Journeyman  |
|     46 | Ava          | Cruz        |   2024 |       6 |            4.17 | Journeyman  |
|     46 | Ava          | Cruz        |   2025 |       4 |            2.17 | Journeyman  |
|     46 | Ava          | Cruz        |   2025 |      11 |            9    | Journeyman  |
|     47 | Jackson      | Fernandez   |   2024 |       2 |            5.5  | Trainee     |
|     47 | Jackson      | Fernandez   |   2024 |       7 |            2.33 | Trainee     |
|     47 | Jackson      | Fernandez   |   2025 |       5 |            4.67 | Trainee     |
|     47 | Jackson      | Fernandez   |   2025 |      11 |            9    | Trainee     |
|     48 | Mia          | Ruiz        |   2024 |       3 |            6.17 | Senior      |
|     48 | Mia          | Ruiz        |   2024 |       8 |            2.67 | Senior      |
|     48 | Mia          | Ruiz        |   2025 |       6 |            2.5  | Senior      |
|     48 | Mia          | Ruiz        |   2025 |      11 |           10    | Senior      |
|     49 | Liam         | Alvarez     |   2024 |       4 |            8.33 | Journeyman  |
|     49 | Liam         | Alvarez     |   2024 |       9 |            1.83 | Journeyman  |
|     49 | Liam         | Alvarez     |   2025 |       7 |            5    | Journeyman  |
|     49 | Liam         | Alvarez     |   2025 |      11 |           10    | Journeyman  |
|     50 | Charlotte    | Morales     |   2024 |       5 |            8.83 | Trainee     |
|     50 | Charlotte    | Morales     |   2024 |      10 |            1.67 | Trainee     |
|     50 | Charlotte    | Morales     |   2025 |       8 |            2.83 | Trainee     |
|     50 | Charlotte    | Morales     |   2025 |      11 |           10    | Trainee     |

## Report 4: Schedule crew for flight (FlightID: 101)

This report suggests available crew members for scheduling on a specific flight, prioritizing those with the most rest time.

| Crew ID   | Crew Name      | Base City   | Crew Type        | Rest Time   | Seniority   |
|:----------|:---------------|:------------|:-----------------|:------------|:------------|
| 6         | Sarah Brown    | New York    | Pilot            | 518 hours   | Trainee     |
| 36        | Kayla Santiago | New York    | Flight Attendant | 61 hours    | Senior      |
| 26        | Justin Ramos   | New York    | Flight Attendant | 52 hours    | Trainee     |
| 1         | John Doe       | New York    | Pilot            | 30 hours    | Senior      |
| 46        | Ava Cruz       | New York    | Flight Attendant | 23 hours    | Journeyman  |

