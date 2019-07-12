import pandas as pd
import CLperfDB
import KustoBackup
import KustoFailover

"""
constants
"""
RESPONSE_TIME_90TH_PERCENTILE_TRASHOLD = 1

"""
This class represents benchmark result. It is adjusted to my needs, since I tune certain parameters
"""
class Result(object):
    def __init__(self,
                run_id,
                max_outstanding_io,
                volume_io_request_size_bytes,
                max_log_rate,
                start_time,
                end_time,
                transactions_per_minute,
                response_time_90th_percentile,
                failover_kusto_test,
                backup_kusto_test):

        self.run_id = run_id
        self.max_outstanding_io = max_outstanding_io
        self.volume_io_request_size_bytes = volume_io_request_size_bytes
        self.max_log_rate = max_log_rate

        #strings
        self.start_time = start_time
        self.end_time = end_time

        self.transactions_per_minute = transactions_per_minute
        self.response_time_90th_percentile = response_time_90th_percentile

        #tuple (redo_stats.avg, failover_time_stats.avg)
        self.backup_kusto_test = float(backup_kusto_test)
        self.failover_kusto_test = (float(failover_kusto_test[0]), float(failover_kusto_test[1]))
        
        self.loss = self.get_loss()

    def __str__(self):
        return "Result:\nrun_id" + str(self.run_id) + " max_outstanding_io " + str(self.max_outstanding_io) + " volume_io_request_size_bytes " + str(self.volume_io_request_size_bytes) + " max_log_rate " + str(self.max_log_rate) + " start_time " + str(self.start_time) + " end_time " + str(self.end_time) + "\ntransactions_per_minute " + str(self.transactions_per_minute) + " response_time_90th_percentile " + str(self.response_time_90th_percentile) + " failover_kusto_test " + str(self.failover_kusto_test) + " backup_kusto_test " + str(self.backup_kusto_test)
            

    def response_time_loss(self):
        return (self.response_time_90th_percentile < 1) + (1 <= self.response_time_90th_percentile < 2) * (-self.response_time_90th_percentile + 2)

    def failover_kusto_test_loss(self):
        redo_stats_avg = self.failover_kusto_test[0]
        failover_time_stats_avg = self.failover_kusto_test[1]
        return (redo_stats_avg < 0.1) * ((failover_time_stats_avg < 1) + (1 <= failover_time_stats_avg < 2) * (-failover_time_stats_avg + 2))

    def backup_kusto_test_loss(self):
        return (self.backup_kusto_test < 5) + (5 <= self.backup_kusto_test < 10) * (-self.backup_kusto_test/5 + 2)

  
    def get_loss(self):
        return self.transactions_per_minute*self.response_time_loss()*self.failover_kusto_test_loss()*self.backup_kusto_test_loss()

    @staticmethod
    def results_to_data_frame(results):
        return pd.DataFrame([vars(result) for result in results])

    @staticmethod
    def read_result(benchmark_run, kusto_client):
        run_id = benchmark_run.run_id

        start_time = CLperfDB.benchmark_start_time(benchmark_run)
        end_time = CLperfDB.benchmark_end_time(benchmark_run)

        max_outstanding_io = benchmark_run.config_overrides.config_dict['SQL.Config_RgSettings_LocalVolumeMaxOutstandingIo']
        volume_io_request_size_bytes = benchmark_run.config_overrides.config_dict['SQL.Config_RgSettings_LocalVolumeIORequestSizeBytes']
        max_log_rate = benchmark_run.property_overrides.instance_settings_dict['MaxLogRate']

        results = CLperfDB.read_results_benchmark(benchmark_run)

        try:
            transactions_per_minute = results['Transactions per minute']
        except:
            transactions_per_minute = None

        try:
            response_time_90th_percentile = results['90th percentile']
        except:
            response_time_90th_percentile = None

        failover_kusto_test = KustoFailover.failover_kusto_test(kusto_client, benchmark_run)
        backup_kusto_test = KustoBackup.backup_kusto_test(kusto_client, benchmark_run)

        return Result(run_id, max_outstanding_io, volume_io_request_size_bytes, max_log_rate, start_time, end_time, transactions_per_minute,
                        response_time_90th_percentile, failover_kusto_test, backup_kusto_test)

    
    #we all have all info
    def successful_run(self):   

        if self.run_id is None:
            return False

        if self.failover_kusto_test[0] == -2 or self.backup_kusto_test == -2:
            return False

        if self.end_time is None or self.start_time is None:
            return False

        if self.transactions_per_minute is None:
            return False

        if self.max_outstanding_io is None or self.volume_io_request_size_bytes is None or self.max_log_rate is None:
            return False

        return True
