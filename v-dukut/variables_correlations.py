import rbf
import sys
import pandas as pd
import numpy as np

file_name = sys.argv[1]
df = pd.read_csv('Analitics/' + file_name)

max_outstanding_io = df['max_outstanding_io'].values
request_size_bytes = df['volume_io_request_size_bytes'].values
max_log_rate = df['max_log_rate'].values

transactions_per_minute = df['transactions_per_minute'].values
response_time_90th_percentile = df['response_time_90th_percentile'].values

backup_kusto_test = df['backup_kusto_test'].values
failover_list = df['failover_kusto_test'].tolist()
redo_queue_list = []
failover_stats_list = []

for item in failover_list:
    tmp = item[1:-1].split(',')
    redo_queue_list.append(float(tmp[0]))
    failover_stats_list.append(float(tmp[1]))

df['redo_queue'] = redo_queue_list
df['failover'] = failover_stats_list
correlation = df.corr(method= 'pearson')
correlation.to_csv('Analitics/Correlation' + file_name)