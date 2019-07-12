from Result import Result
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import pandas as pd
import numpy as np
import sys

def export_result_from_csv(results_dataframe):

    result_list = []

    for index, row in results_dataframe.iterrows():
        failover_kusto_test = (row.failover_kusto_test[1:-1].split(',')[0], row.failover_kusto_test[1:-1].split(',')[1])
        result_list.append(Result(row.run_id, row.max_outstanding_io, row.volume_io_request_size_bytes, row.max_log_rate, row.start_time, row.end_time, row.transactions_per_minute, row.response_time_90th_percentile, failover_kusto_test, row.backup_kusto_test))
    export_results(result_list)
    

def export_results(results):

    print("plotting results for len list " + str(len(results)))

    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    #x = [result.max_outstanding_io for result in results]
    #y =[result.volume_io_request_size_bytes/1024 for result in results]
    #z =[result.max_log_rate/1024/1024 for result in results]

    x_good = [result.max_outstanding_io for result in results if result.loss > 0]
    y_good =[result.volume_io_request_size_bytes/1024 for result in results if result.loss > 0]
    z_good =[result.max_log_rate/1024/1024 for result in results if result.loss > 0]

    x_failed = [result.max_outstanding_io for result in results if result.loss == 0]
    y_failed =[result.volume_io_request_size_bytes/1024 for result in results if result.loss == 0]
    z_failed =[result.max_log_rate/1024/1024 for result in results if result.loss == 0]
    
    #color_good = [result.get_loss() for result in results]
    color_good = [result.get_loss() for result in results if result.loss > 0]

    e_max = np.max(color_good)
    e_min = np.min(color_good)

    color_failed = [(result.get_loss()-e_min)/(e_max - e_min) for result in results if result.loss == 0]

    color_good_normed = [50*(result.get_loss()-e_min)/(e_max - e_min) for result in results if result.loss > 0]
    ax.scatter(x_failed, y_failed, z_failed,  s =50  , c= 'red', marker='x')
    ax.scatter(x_good, y_good, z_good, s= color_good_normed,  c= color_good_normed, marker='o')
    
    ax.set_xlabel('disk queue')
    ax.set_ylabel('normalized io in KB')
    ax.set_zlabel('max log rate in MB/s')
    ax.set_xlim([32,1024])
    ax.set_ylim([8, 512])
    ax.set_zlim([20, 120])

    #I want that my picture name has format results-06-05-18-42 if we are making it on June 5th in 18:42 
    plt.show()

file_name = sys.argv[1]
df = pd.read_csv('Analitics/' + file_name)

export_result_from_csv(df)