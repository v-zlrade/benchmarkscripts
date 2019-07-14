from mpl_toolkits.mplot3d import Axes3D
from Result import Result
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import re
import common_functions

"""
export from result objects
Exporting list of result objects to local .png (picture contains current timestamp in name)
"""
def export_results(results):

    print("plotting results for len list " + str(len(results)))

    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    x = [result.max_outstanding_io for result in results]
    y =[result.volume_io_request_size_bytes for result in results]
    z =[result.max_log_rate for result in results]

    color = [result.get_loss() for result in results]

    ax.scatter(x, y, z, c= color, marker='o')

    ax.set_xlabel('max outstanding io')
    ax.set_ylabel('volume io request size bytes')
    ax.set_zlabel('max log rate')

    #I want that my picture name has format results-06-05-18-42 if we are making it on June 5th in 18:42 
    plot_name = 'results' + common_functions.current_timestamp() + '.png'
    fig.savefig('Plots/' + plot_name)

"""
export from csv objects
Exporting list of result objects to local .png (picture contains current timestamp in name)
"""
def export_result_from_csv(results_dataframe):

    result_list = [Result(row.run_id, row.max_outstanding_io, row.volume_io_request_size_bytes, row.max_log_rate, row.start_time, row.end_time, row.transactions_per_minute, row.response_time_90th_percentile, row.failover_kusto_test, row.backup_kusto_test) for index, row in results_dataframe.iterrows()]
    return export_results(result_list)