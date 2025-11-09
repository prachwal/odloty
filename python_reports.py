import pyodbc
from fpdf import FPDF
from tabulate import tabulate

# Connection details
server = 'localhost'
port = '1433'
database = 'CrewSchedulingDB'
username = 'sa'
password = 'P@ssw0rd7sjnus!'

# Connection string
conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server},{port};DATABASE={database};UID={username};PWD={password}'

class CrewReportsPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.set_margins(5, 5, 5)

    def header(self):
        self.set_font('Arial', 'B', 16)
        self.cell(0, 10, 'Crew Scheduling System Reports', 0, 1, 'C')
        self.ln(10)

    def chapter_title(self, title):
        self.set_font('Arial', 'B', 14)
        self.cell(0, 10, title, 0, 1, 'L')
        self.ln(5)

    def add_table(self, headers, data, col_widths=None):
        if col_widths is None:
            col_width = (self.w - self.l_margin - self.r_margin) / len(headers)
            col_widths = [col_width] * len(headers)
        self.set_font('Arial', 'B', 8)
        for i, header in enumerate(headers):
            self.cell(col_widths[i], 8, header, 1, 0, 'C')
        self.ln()
        self.set_font('Arial', '', 5)
        for row in data:
            for i, item in enumerate(row):
                self.cell(col_widths[i], 6, str(item), 1, 0, 'L')
            self.ln()

def get_connection():
    return pyodbc.connect(conn_str)

def add_md_title(md_content, title):
    md_content.append(f"## {title}\n\n")

def add_md_table(md_content, headers, data, description=""):
    if description:
        md_content.append(f"{description}\n\n")
    if data:
        table = tabulate(data, headers=headers, tablefmt="pipe")
        md_content.append(table + "\n\n")
    else:
        md_content.append("No data available.\n\n")

def add_task_description_md(md_content):
    add_md_title(md_content, "Task Description")
    task_text = """
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
    """
    md_content.append(task_text + "\n\n")

def add_task_description(pdf):
    pdf.chapter_title("Task Description")
    task_text = """
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
    """
    pdf.set_font('Arial', '', 8)
    pdf.multi_cell(0, 5, task_text)
    pdf.ln()

def report_crew_in_flight(pdf):
    pdf.set_font('Arial', '', 10)
    pdf.multi_cell(0, 5, "This report shows all crew members currently on planes in flight, including their flight details and roles.")
    pdf.ln(2)
    pdf.chapter_title("Report 1: Crew currently in flight")
    query = """
    SELECT ca.CrewID, c.FirstName, c.LastName, f.FlightID, f.FlightNumber,
           dep.City AS DepartureCity, dest.City AS DestinationCity,
           f.ActualDeparture AS DepartureTime,
           DATEADD(MINUTE, f.FlightDuration, f.ActualDeparture) AS ArrivalTime,
           r.RoleName AS Role, sl.SeniorityName AS Seniority
    FROM CrewAssignments ca
    JOIN Crew c ON ca.CrewID = c.CrewID
    JOIN Flights f ON ca.FlightID = f.FlightID
    JOIN Airports dep ON f.DepartureAirportID = dep.AirportID
    JOIN Airports dest ON f.DestinationAirportID = dest.AirportID
    JOIN Roles r ON ca.RoleID = r.RoleID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE f.StatusID = 2
    ORDER BY f.FlightID, ca.RoleID DESC, c.LastName
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Flight', 'Flight Number', 'Departure City', 'Destination City', 'Departure Time', 'Arrival Time', 'Role', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.FlightID, row.FlightNumber, row.DepartureCity, row.DestinationCity, str(row.DepartureTime), str(row.ArrivalTime), row.Role, row.Seniority] for row in rows]
    if data:
        col_widths = [12, 17, 17, 12, 17, 22, 22, 27, 27, 17, 12]
        pdf.add_table(headers, data, col_widths)
    else:
        pdf.cell(0, 10, "No crew currently in flight.", 0, 1)
    conn.close()

def report_crew_exceeding_limits(pdf):
    pdf.set_font('Arial', '', 10)
    pdf.multi_cell(0, 5, "This report lists crew members who have exceeded or are at risk of exceeding their work hour limitations as per regulatory requirements.")
    pdf.ln(2)
    pdf.chapter_title("Report 2: Crew exceeding hour limits")
    query = """
    SELECT c.CrewID, c.FirstName, c.LastName,
           HL.Hours168, HL.Hours672, HL.Hours365Days,
           HL.LimitStatus AS WithinLimits,
           sl.SeniorityName AS Seniority
    FROM Crew c
    CROSS APPLY dbo.fn_CheckHourLimits(c.CrewID) HL
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE HL.ExceedsLimits = 1
    ORDER BY c.CrewID
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Hours 168h', 'Hours 672h', 'Hours 365d', 'Limit Status', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.Hours168, row.Hours672, row.Hours365Days, row.WithinLimits, row.Seniority] for row in rows]
    if data:
        col_widths = [12, 17, 17, 17, 17, 17, 22, 12]
        pdf.add_table(headers, data, col_widths)
    else:
        pdf.cell(0, 10, "No crew exceeding hour limits.", 0, 1)
    conn.close()

def report_monthly_hours(pdf):
    pdf.set_font('Arial', '', 10)
    pdf.multi_cell(0, 5, "This report provides a summary of hours worked per month by each crew member to support payroll processing.")
    pdf.ln(2)
    pdf.chapter_title("Report 3: Monthly hours worked by crew")
    query = """
    SELECT c.CrewID, c.FirstName, c.LastName,
           YEAR(f.ScheduledDeparture) AS Year,
           MONTH(f.ScheduledDeparture) AS Month,
           SUM(f.FlightDuration / 60.0) AS MonthlyHours,
           sl.SeniorityName AS Seniority
    FROM CrewAssignments ca
    JOIN Crew c ON ca.CrewID = c.CrewID
    JOIN Flights f ON ca.FlightID = f.FlightID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE f.StatusID = 3
    GROUP BY c.CrewID, c.FirstName, c.LastName, YEAR(f.ScheduledDeparture), MONTH(f.ScheduledDeparture), sl.SeniorityName
    ORDER BY c.CrewID, Year, Month
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Year', 'Month', 'Monthly Hours', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.Year, row.Month, f"{row.MonthlyHours:.2f}", row.Seniority] for row in rows]
    if data:
        col_widths = [12, 17, 17, 12, 12, 17, 12]
        pdf.add_table(headers, data, col_widths)
    else:
        pdf.cell(0, 10, "No monthly hours data.", 0, 1)
    conn.close()

def report_schedule_crew_for_flight(pdf, flight_id=1):
    pdf.set_font('Arial', '', 10)
    pdf.multi_cell(0, 5, "This report suggests available crew members for scheduling on a specific flight, prioritizing those with the most rest time.")
    pdf.ln(2)
    pdf.chapter_title(f"Report 4: Schedule crew for flight (FlightID: {flight_id})")
    query = """
    SELECT TOP 5 c.CrewID, c.FirstName, c.LastName, a.City AS BaseCity,
           ct.CrewTypeName AS CrewType,
           dbo.fn_CalculateRestTime(c.CrewID, ?) AS RestTimeHours,
           sl.SeniorityName AS Seniority
    FROM Crew c
    JOIN Airports a ON c.BaseAirportID = a.AirportID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    JOIN CrewTypes ct ON c.CrewTypeID = ct.CrewTypeID
    WHERE c.IsActive = 1
    AND NOT EXISTS (SELECT 1 FROM dbo.fn_CheckHourLimits(c.CrewID) WHERE ExceedsLimits = 1)
    AND c.BaseAirportID = (SELECT DepartureAirportID FROM Flights WHERE FlightID = ?)
    ORDER BY RestTimeHours DESC
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query, (flight_id, flight_id))
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Base City', 'Crew Type', 'Rest Time Hours', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.BaseCity, row.CrewType, row.RestTimeHours, row.Seniority] for row in rows]
    if data:
        col_widths = [12, 17, 17, 22, 15, 17, 12]
        pdf.add_table(headers, data, col_widths)
    else:
        pdf.cell(0, 10, "No available crew found.", 0, 1)
    conn.close()

def report_crew_in_flight_md(md_content):
    add_md_title(md_content, "Report 1: Crew currently in flight")
    description = "This report shows all crew members currently on planes in flight, including their flight details and roles."
    query = """
    SELECT ca.CrewID, c.FirstName, c.LastName, f.FlightID, f.FlightNumber,
           dep.City AS DepartureCity, dest.City AS DestinationCity,
           f.ActualDeparture AS DepartureTime,
           DATEADD(MINUTE, f.FlightDuration, f.ActualDeparture) AS ArrivalTime,
           r.RoleName AS Role, sl.SeniorityName AS Seniority
    FROM CrewAssignments ca
    JOIN Crew c ON ca.CrewID = c.CrewID
    JOIN Flights f ON ca.FlightID = f.FlightID
    JOIN Airports dep ON f.DepartureAirportID = dep.AirportID
    JOIN Airports dest ON f.DestinationAirportID = dest.AirportID
    JOIN Roles r ON ca.RoleID = r.RoleID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE f.StatusID = 3
    ORDER BY f.FlightID, ca.RoleID DESC, c.LastName
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Flight', 'Flight Number', 'Departure City', 'Destination City', 'Departure Time', 'Arrival Time', 'Role', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.FlightID, row.FlightNumber, row.DepartureCity, row.DestinationCity, str(row.DepartureTime), str(row.ArrivalTime), row.Role, row.Seniority] for row in rows]
    add_md_table(md_content, headers, data, description)
    conn.close()

def report_crew_exceeding_limits_md(md_content):
    add_md_title(md_content, "Report 2: Crew exceeding hour limits")
    description = "This report lists crew members who have exceeded or are at risk of exceeding their work hour limitations as per regulatory requirements."
    query = """
    SELECT c.CrewID, c.FirstName, c.LastName,
           HL.Hours168, HL.Hours672, HL.Hours365Days,
           HL.LimitStatus AS WithinLimits,
           sl.SeniorityName AS Seniority
    FROM Crew c
    CROSS APPLY dbo.fn_CheckHourLimits(c.CrewID) HL
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE HL.ExceedsLimits = 1
    ORDER BY c.CrewID
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Hours 168h', 'Hours 672h', 'Hours 365d', 'Limit Status', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.Hours168, row.Hours672, row.Hours365Days, row.WithinLimits, row.Seniority] for row in rows]
    add_md_table(md_content, headers, data, description)
    conn.close()

def report_monthly_hours_md(md_content):
    add_md_title(md_content, "Report 3: Monthly hours worked by crew")
    description = "This report provides a summary of hours worked per month by each crew member to support payroll processing."
    query = """
    SELECT c.CrewID, c.FirstName, c.LastName,
           YEAR(f.ScheduledDeparture) AS Year,
           MONTH(f.ScheduledDeparture) AS Month,
           SUM(f.FlightDuration / 60.0) AS MonthlyHours,
           sl.SeniorityName AS Seniority
    FROM CrewAssignments ca
    JOIN Crew c ON ca.CrewID = c.CrewID
    JOIN Flights f ON ca.FlightID = f.FlightID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    WHERE f.StatusID = 3
    GROUP BY c.CrewID, c.FirstName, c.LastName, YEAR(f.ScheduledDeparture), MONTH(f.ScheduledDeparture), sl.SeniorityName
    ORDER BY c.CrewID, Year, Month
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Year', 'Month', 'Monthly Hours', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.Year, row.Month, f"{row.MonthlyHours:.2f}", row.Seniority] for row in rows]
    add_md_table(md_content, headers, data, description)
    conn.close()

def report_schedule_crew_for_flight_md(md_content, flight_id=1):
    add_md_title(md_content, f"Report 4: Schedule crew for flight (FlightID: {flight_id})")
    description = "This report suggests available crew members for scheduling on a specific flight, prioritizing those with the most rest time."
    query = """
    SELECT TOP 5 c.CrewID, c.FirstName, c.LastName, a.City AS BaseCity,
           ct.CrewTypeName AS CrewType,
           dbo.fn_CalculateRestTime(c.CrewID, ?) AS RestTimeHours,
           sl.SeniorityName AS Seniority
    FROM Crew c
    JOIN Airports a ON c.BaseAirportID = a.AirportID
    JOIN SeniorityLevels sl ON c.SeniorityID = sl.SeniorityID
    JOIN CrewTypes ct ON c.CrewTypeID = ct.CrewTypeID
    WHERE c.IsActive = 1
    AND NOT EXISTS (SELECT 1 FROM dbo.fn_CheckHourLimits(c.CrewID) WHERE ExceedsLimits = 1)
    AND c.BaseAirportID = (SELECT DepartureAirportID FROM Flights WHERE FlightID = ?)
    ORDER BY RestTimeHours DESC
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query, (flight_id, flight_id))
    rows = cursor.fetchall()
    headers = ['Crew', 'First Name', 'Last Name', 'Base City', 'Crew Type', 'Rest Time Hours', 'Seniority']
    data = [[row.CrewID, row.FirstName, row.LastName, row.BaseCity, row.CrewType, row.RestTimeHours, row.Seniority] for row in rows]
    add_md_table(md_content, headers, data, description)
    conn.close()

if __name__ == "__main__":
    try:
        # Generate PDF
        pdf = CrewReportsPDF()
        pdf.add_page()
        
        add_task_description(pdf)
        pdf.add_page()
        report_crew_in_flight(pdf)
        pdf.add_page()
        report_crew_exceeding_limits(pdf)
        pdf.add_page()
        report_monthly_hours(pdf)
        pdf.add_page()
        report_schedule_crew_for_flight(pdf)
        
        pdf.output("crew_reports.pdf")
        print("PDF report generated: crew_reports.pdf")
        
        # Generate Markdown
        md_content = []
        md_content.append("# Crew Scheduling System Reports\n\n")
        add_task_description_md(md_content)
        report_crew_in_flight_md(md_content)
        report_crew_exceeding_limits_md(md_content)
        report_monthly_hours_md(md_content)
        report_schedule_crew_for_flight_md(md_content)
        
        with open("crew_reports.md", "w") as f:
            f.write("".join(md_content))
        print("Markdown report generated: crew_reports.md")
    except Exception as e:
        print(f"Error: {e}")