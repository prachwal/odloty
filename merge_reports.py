#!/usr/bin/env python3
"""
Crew Scheduling System - Complete Report Generator
This script runs all SQL files in sequence and generates a comprehensive report
combining SQL execution results and formatted reports.
"""

import subprocess
import sys
import os
from datetime import datetime

def run_sql_file(filename, description):
    """Run a SQL file using sqlcmd and return the output."""
    print(f"Running {filename}: {description}")
    try:
        result = subprocess.run([
            'sqlcmd',
            '-S', 'localhost',
            '-U', 'sa',
            '-P', 'P@ssw0rd7sjnus!',
            '-i', filename
        ], capture_output=True, text=True, cwd=os.getcwd())

        if result.returncode == 0:
            print(f"✓ {filename} completed successfully")
            return result.stdout
        else:
            print(f"✗ {filename} failed with error code {result.returncode}")
            print(f"Error: {result.stderr}")
            return f"ERROR in {filename}:\n{result.stderr}\n{result.stdout}"

    except Exception as e:
        print(f"✗ Failed to run {filename}: {str(e)}")
        return f"EXCEPTION in {filename}: {str(e)}"

def generate_python_reports():
    """Generate PDF and Markdown reports using python_reports.py"""
    print("Generating Python reports...")
    try:
        result = subprocess.run([
            'python3', 'python_reports.py'
        ], capture_output=True, text=True, cwd=os.getcwd())

        if result.returncode == 0:
            print("✓ Python reports generated successfully")
            return result.stdout
        else:
            print(f"✗ Python reports failed: {result.stderr}")
            return f"ERROR in python_reports.py:\n{result.stderr}\n{result.stdout}"

    except Exception as e:
        print(f"✗ Failed to generate Python reports: {str(e)}")
        return f"EXCEPTION in python_reports.py: {str(e)}"

def read_markdown_report():
    """Read the generated crew_reports.md file"""
    try:
        with open('crew_reports.md', 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"ERROR reading crew_reports.md: {str(e)}"

def main():
    """Main function to run all SQL files and generate complete report"""

    # SQL files to run in sequence
    sql_files = [
        ('00_reset_crew_database.sql', 'Reset database'),
        ('01_create_crew_database.sql', 'Create database schema'),
        ('02_insert_crew_data.sql', 'Insert test data'),
        ('03_crew_logic.sql', 'Create business logic'),
        ('04_test_crew_logic.sql', 'Run tests'),
        ('05_reports.sql', 'Generate SQL reports')
    ]

    # Collect all outputs
    complete_report = []

    # Header
    complete_report.append("# Crew Scheduling System - Complete Execution Report")
    complete_report.append(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    complete_report.append("")

    # Run SQL files
    complete_report.append("## SQL Execution Results")
    complete_report.append("")

    sql_outputs = []
    for filename, description in sql_files:
        output = run_sql_file(filename, description)
        sql_outputs.append(f"### {filename} - {description}")
        sql_outputs.append("```sql")
        sql_outputs.append(f"-- {description}")
        sql_outputs.append("-- Output:")
        sql_outputs.append(output)
        sql_outputs.append("```")
        sql_outputs.append("")

    complete_report.extend(sql_outputs)

    # Generate Python reports
    complete_report.append("## Python Report Generation")
    complete_report.append("")
    python_output = generate_python_reports()
    complete_report.append("```bash")
    complete_report.append("python3 python_reports.py")
    complete_report.append(python_output)
    complete_report.append("```")
    complete_report.append("")

    # Include the generated Markdown report
    complete_report.append("## Generated Reports")
    complete_report.append("")
    md_content = read_markdown_report()
    complete_report.append(md_content)

    # Write complete report
    with open('complete_system_report.md', 'w', encoding='utf-8') as f:
        f.write('\n'.join(complete_report))

    print("\n✓ Complete report generated: complete_system_report.md")

if __name__ == "__main__":
    main()