import sys

def process_csv_data(csv_data):
    # split the data into lines
    lines = csv_data.strip().split('\n')

    # initialize variables
    output = []
    current_start = None
    current_end = None

    # process each line
    for line in lines:
        parts = line.split('|')
        date = parts[0].strip()
        start_time = parts[1].strip()
        end_time = parts[2].strip()

        if current_start is None:
            current_start = start_time
            current_end = end_time
        else:
            if start_time != current_end:
                output.append(f"{date} | {current_start} | {current_end}")
                current_start = start_time
            current_end = end_time

    # append the last interval
    if current_start is not None:
        output.append(f"{date} | {current_start} | {current_end}")

    return output

if __name__ == "__main__":
    # read csv data from stdin
    csv_data = sys.stdin.read()
    result = process_csv_data(csv_data)

    # print the result
    for interval in result:
        print(interval)
