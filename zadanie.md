
# TECHNICAL AUDITION

Below is your audition scenario. Please prepare a solution to the problem described.  Please arrive ready to present your solution, in whatever fashion you feel most comfortable (e.g. whiteboard, written design, UML, PowerPoint, pseudo code, actual code), to a panel of 3 to 4 interviewers. Once you have presented your solution, the interviewers will ask questions and provide additional requirements that you will have to incorporate into your design on the fly. This process gives us a chance to see how you solve problems, how advanced your design skills are, how well you present to a group, and how well you think on your feet. The technical audition will last approximately one hour. Please let us know if you have any questions before the interview.

## DESIGNING AN ARCHITECTURE FOR WORLDWIDE CREW SCHEDULING

Consider an application to handle the scheduling of airline crews for commercial flights. This application is used by airline station managers to ensure that every departing flight has two pilots (with at least one pilot being a “senior” or “captain”) and a cabin crew of three people where one of the cabin crew is a senior level flight attendant.
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
