from azure.kusto.data.request import KustoClient, KustoConnectionStringBuilder
from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data.helpers import dataframe_from_result_table

cluster_name = "https://sqlazureweu2.kustomfa.windows.net"
kustoStringBuilder = KustoConnectionStringBuilder.with_aad_device_authentication(cluster_name)
kusto_client = KustoClient(kustoStringBuilder)

query = '''MonDmDbHadrReplicaStates
| where TIMESTAMP > datetime(2019-06-16 12:39:52) and TIMESTAMP < datetime(2019-06-16 13:21:05)
| where LogicalServerName == "clperftesting-gen5-bc8-loose24-ac-weu-00"
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
| project redo_stats.avg, failover_time_stats.max'''

try:
    print("querying")
    failover_response = kusto_client.execute("sqlazure1", query)
    print("response")
    print(failover_response)

    failover_df = dataframe_from_result_table(failover_response.primary_results[0])
    print("dataframe")
    print(failover_df)

    print(failover_df['redo_stats_avg'])

    redo_stats_avg = failover_df['redo_stats_avg'].mean()
    failover_time_stats_max = failover_df['failover_time_stats_max'].max()

    a =  (redo_stats_avg , failover_time_stats_max)
except:
    a = (-2, -2)

print(a)