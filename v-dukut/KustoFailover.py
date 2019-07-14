from azure.kusto.data.request import KustoClient, KustoConnectionStringBuilder
from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data.helpers import dataframe_from_result_table
import pandas as pd
import re
import time
import CLperfDB
#from Benchmark_run import Benchmark_run

"""
constants
"""

hadr_replica_states_query = '''
MonDmDbHadrReplicaStates
| where TIMESTAMP > datetime(start_time_variable) and TIMESTAMP < datetime(end_time_variable)
| where LogicalServerName == "server_name_variable"
| where isnotempty(toguid(logical_database_name))
| where is_primary_replica == 0 and is_local == 1
| project
    TIMESTAMP,
    NodeName,
    redo_queue_size_mb = redo_queue_size /1024.,
    redo_rate,
    failover_time_sec = redo_queue_size*1.0/redo_rate
| order by TIMESTAMP asc
| summarize redo_queue_list = make_list(redo_queue_size_mb), time_series = make_list(TIMESTAMP), failover_time_sec_list = make_list(failover_time_sec) by NodeName 
| extend redo_diff_mb= series_fir(redo_queue_list, dynamic([1,-1]), false, false)
| extend redo_stats = series_stats_dynamic(redo_diff_mb)
| extend failover_time_smooth_secs = series_fir(failover_time_sec_list, dynamic ([1,1,1]), true, true) //normalize= true, center= true
| extend failover_time_stats = series_stats_dynamic(failover_time_smooth_secs)
| project redo_stats.avg, failover_time_stats.max
'''


"""
returns -1 if benchmark run has not started (or ended)
        -2 querying kusto failed
        1 if backup_kusto_test failed (we don't want this)
        0 if everything is fine
"""
def failover_kusto_test(client, benchmark_run):

    start_time_variable = CLperfDB.benchmark_start_time(benchmark_run)
    end_time_variable = CLperfDB.benchmark_end_time(benchmark_run)

    if start_time_variable is None or end_time_variable is None:
        return (-1, -1) 

    query_ = re.sub("start_time_variable", start_time_variable, hadr_replica_states_query)
    query_ = re.sub("end_time_variable", end_time_variable, query_)
    query_ = re.sub("server_name_variable", benchmark_run.get_logical_server_name(), query_)

    print("Querying kusto (failover info)")
    print("Query text \n " + query_)

    try:
        failover_response = client.execute("sqlazure1", query_)
        failover_df = dataframe_from_result_table(failover_response.primary_results[0])

        redo_stats_avg = failover_df['redo_stats_avg'].max()
        failover_time_stats_max = failover_df['failover_time_stats_max'].max()

        a =  (redo_stats_avg , failover_time_stats_max)
        
        return a
    except:
        return (-2, -2)