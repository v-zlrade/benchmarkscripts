from azure.kusto.data.request import KustoClient, KustoConnectionStringBuilder
from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data.helpers import dataframe_from_result_table
import pandas as pd
import re
import time
import CLperfDB


backup_query = '''
MonBackup
| where package == "XdbBackupServiceXEvents" and AppTypeName == "Worker.CL" 
| where TIMESTAMP > datetime(start_time_variable) and TIMESTAMP < datetime(end_time_variable)
| where LogicalServerName == "server_name_variable" and database_name == tostring(toguid(database_name))
| where (event_type == "BACKUP_START")
| extend backup_start_time = TIMESTAMP
| where backup_type == "Log"
| join kind = inner (
MonBackup
| where package == "XdbBackupServiceXEvents" and AppTypeName == "Worker.CL" 
| where TIMESTAMP > datetime(start_time_variable) and TIMESTAMP < datetime(end_time_variable)
| where LogicalServerName == "server_name_variable"  and database_name == tostring(toguid(database_name))
| where (event_type == "BACKUP_END")
| extend backup_end_time = TIMESTAMP
| where backup_type == "Log"
) on backup_path, database_name
| extend backup_duration_min = (backup_end_time - backup_start_time)/(1s) / 60.
| project backup_duration_min
'''

"""
returns -1 if benchmark run has not started (or ended)
        -2 querying kusto failed
        1 if backup_kusto_test failed (we don't want this)
        0 if everything is fine
"""
def backup_kusto_test(client, benchmark_run):

    CLperfDB.benchmark_start_time(benchmark_run)
    CLperfDB.benchmark_end_time(benchmark_run)

    print(benchmark_run.start_time)
    print(benchmark_run.end_time)

    if benchmark_run.start_time is None or benchmark_run.end_time is None:
        return -1 

    query_ = re.sub("start_time_variable", benchmark_run.start_time, backup_query)
    query_ = re.sub("end_time_variable", benchmark_run.end_time, query_)
    query_ = re.sub("server_name_variable", benchmark_run.get_logical_server_name(), query_)

    print("Querying kusto (backup info)")
    print("Query text \n " + query_)


    try:
        backup_response = client.execute("sqlazure1", query_)
        backup_df = dataframe_from_result_table(backup_response.primary_results[0])
        
        return backup_df['backup_duration_min'].max()
    except:
        return -2