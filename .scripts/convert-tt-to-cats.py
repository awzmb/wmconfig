import sys
import csv
from datetime import datetime, timedelta
from collections import defaultdict

# Function to calculate time difference in hours
def calculate_hours(start, end):
    fmt = '%H:%M'
    start_time = datetime.strptime(start, fmt)
    end_time = datetime.strptime(end, fmt)
    return (end_time - start_time).total_seconds() / 3600.0

# Dictionary to store total hours per date and task
hours_per_date_task = defaultdict(float)

# Read and process input from stdin (piped data)
input_data = sys.stdin.readlines()
reader = csv.reader(input_data, delimiter='|')
for row in reader:
    if len(row) >= 6:  # Ensure the row has at least 6 columns
        date = row[0].strip()
        start = row[1].strip()
        end = row[2].strip()
        task = row[5].strip()

        if start and end:  # Only calculate duration if start and end times are provided
            hours = calculate_hours(start, end)
            hours_per_date_task[(date, task)] += hours

# Print the results
for (date, task), hours in hours_per_date_task.items():
    print(f"{date} | {hours:.2f} hours | {task}")
