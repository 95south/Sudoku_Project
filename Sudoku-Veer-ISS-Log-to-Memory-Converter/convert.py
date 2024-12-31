import math
import csv

def hex_to_decimal(hex_string):
    try:
        decimal_value = int(hex_string, 16)
        return str(decimal_value)
    except ValueError:
        return "Invalid hexadecimal input"


def write_array_to_csv(array, output_file):
    """
    Writes a 2D array to a CSV file.

    Args:
        array (list[list]): The 2D array to be written.
        output_file (str): The path to the output CSV file.

    Returns:
        None
    """
    try:
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerows(array)
        print(f"Array successfully written to '{output_file}'.")
    except Exception as e:
        print(f"Error writing to CSV: {e}")

def read_lines_from_bottom(file_path):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
            # Remove leading/trailing whitespaces and newline characters
            lines = [line.strip() for line in lines]
            # Filter lines that end with "lb       t3, 0x0(t2)"
            filtered_lines = [line for line in lines if line.endswith("lb       t3, 0x0(t2)")]
            return filtered_lines
    except FileNotFoundError:
        print(f"File '{file_path}' not found.")
        return []

# Example usage:
input_file_path = '64x64_preloadedTransposed.txt'  # Replace with the actual file path
result_lines = read_lines_from_bottom(input_file_path)
lines_count = len(result_lines)

# Print the extracted lines
print(f"Found {lines_count} lines that end with 'lb       t3, 0x0(t2)':")

sqaure = int(math.sqrt(lines_count))
data = [[0 for _ in range(sqaure)] for _ in range(sqaure)]
for i, line in enumerate(result_lines, start=0):
    print(line.split()[-4], end=" ")
    row = i // sqaure
    col = i % sqaure
    data[row][col] = hex_to_decimal(line.split()[-4]) # type: ignore
    if i % sqaure == 0:
        print()



output_csv_path = 'output.csv'
write_array_to_csv(data, output_csv_path)
