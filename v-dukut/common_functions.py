import re
import CLperfDB
from datetime import datetime
from datetime import timedelta  
import pandas as pd

con = CLperfDB.connect()

def single_to_double_quotes(string_with_single_quotes):
    return re.sub("'", '"', string_with_single_quotes)

"""
returns current timestamp: format monthDayTimeTime
"""
def current_timestamp():
    now = datetime.now()
    date_time = now.strftime("%m/%d/%Y, %H:%M:%S")
    date_time_pattern = r'(\d{2})/(\d{2})/(\d{4}), (\d{2}):(\d{2}):(\d{2})'
    match = re.match(date_time_pattern, date_time)
    return match.group(1) + match.group(2) + match.group(4) + match.group(5) + match.group(6)


def export_dataframe(df, file_name):
    res = df.to_csv()
    file_name = file_name + current_timestamp() + '.csv'

    file = open('Results/' + file_name, 'w+')
    file.write(res)
    file.close()

def add_minutes_to_string_datetime(string_datetime, minutes_to_add):
    #2019-02-26 11:11:44 format
    new_time = datetime.strptime(string_datetime, '%Y-%m-%d %H:%M:%S') + timedelta(minutes= minutes_to_add)
    return datetime.strftime(new_time, '%Y-%m-%d %H:%M:%S')

def Kusto_delay(end_time_string, minutes_to_add = 20, utc_difference = 2):
    if end_time_string is None:
        print("Benchmark is not finished.")
        return False
    time_for_results = datetime.strptime(end_time_string, '%Y-%m-%d %H:%M:%S') + timedelta(minutes= minutes_to_add)
    #changing to utc
    if time_for_results > (datetime.now() - timedelta(hours = utc_difference)):
        print("Benchmark is finished, but we are waiting for Kusto results.")
        return False
    print(time_for_results)
    print("We are ready to read results from Kusto for this benchmark run")
    return True