from Job import Job
from Benchmark_run import Benchmark_run
from Property_Overrides import Property_Overrides
from Config_Overrides import Config_Overrides
from Benchmark_Configs import Benchmark_Configs
from Benchmark_run import Benchmark_run
from Result import Result
import CLperfDB
import time, json, plot, common_functions
from datetime import datetime
from azure.kusto.data.request import KustoClient, KustoConnectionStringBuilder
import pandas as pd

LIMIT_BENCHMARK_RUNS = 30
EXPECTED_DURATION_OF_SLEEPING_IN_MINUTES = 10

cluster_name = "https://sqlazureweu2.kustomfa.windows.net"
kustoStringBuilder = KustoConnectionStringBuilder.with_aad_device_authentication(cluster_name)
kusto_client = KustoClient(kustoStringBuilder)
connection = CLperfDB.connect()

if __name__== "__main__":

    #make kusto client fakely
    fake_response = kusto_client.execute("sqlazure1", "MonBackup|take 1")
    
    number_of_scheduled_benchmarks = 0
    instances_json = open('Configurations/instances.json', 'r+').read()
    instances = json.loads(instances_json)

    #for all jobs
    successful_runs = []
    results = []
    failed_runs = []
    instance_occupation = {}

    for instance_info in instances:
        instance_occupation[instance_info['instance_name']] = -1

    pending_runs = []
    changes = True

    while len(successful_runs) < LIMIT_BENCHMARK_RUNS:

        #for current job
        runs = []
        log_string = ""

        print("Time: " + str(datetime.now()))
        log_string += "Time: " + str(datetime.now()) + '\n'

        print()

        for instance_info in instances:
            available_instance = CLperfDB.is_instance_available(connection, instance_info)

            print("instance " + instance_info['instance_name'] + " available " + str(available_instance))
            log_string += "instance " + instance_info['instance_name'] + " available " + str(available_instance) + "\n"

            if available_instance:
                benchmark_configs = Benchmark_Configs.make_run(instance_info)
                run = Benchmark_run.make_random_run(connection, benchmark_configs)            
                runs.append(run)
                pending_runs.append(run)

        if runs:
            job_identifier = common_functions.current_timestamp()
            job = Job(connection, 'Dubravka_external_' + job_identifier , runs, 'random overrides')

            try:
                success = CLperfDB.schedule_job(job)

                print("Job " + job.name + " has been scheduled. Successful scheduling: " + str(success))
                log_string += "Job " + job.name + " has been scheduled. Successful scheduling: " + str(success) + "\n"

            except:
                print("Failed scheduling job")
                log_string += "Failed scheduling job" + "\n"

        print("I am starting to sleep..")
        log_string += "I am starting to sleep.." + "\n"
        time.sleep(60*EXPECTED_DURATION_OF_SLEEPING_IN_MINUTES)

        print('pending runs len ' + str(len(pending_runs)))
        log_string += 'pending runs len ' + str(len(pending_runs)) + '\n'

        for run in pending_runs:

            #testing purposes
            #run.run_id = 6    
            
            #comment this when testing
            CLperfDB.set_run_id(run)
            CLperfDB.benchmark_start_time(run)
            CLperfDB.benchmark_end_time(run)

            print("Proccessing run: " + str(run) + " start time: " + str(run.start_time) + " end time " + str(run.end_time))
            log_string += "Proccessing run: " + str(run) + " start time: " + str(run.start_time) + " end time " + str(run.end_time) + '\n'

            if run.run_id is not None and common_functions.Kusto_delay(run.end_time): 
                run.read_results(kusto_client)

                print("Benchmark results: transactions per minute: " + str(run.result.transactions_per_minute) + " response time: " + str(run.result.response_time_90th_percentile)) 
                log_string += "Benchmark results: transactions per minute: " + str(run.result.transactions_per_minute) + " response time: " + str(run.result.response_time_90th_percentile) + '\n'
                print("Kusto results: redo_stats.avg " + str(run.result.failover_kusto_test[0]) + " failover_time_stats.max " + str(run.result.failover_kusto_test[1]) + "\n" )
                log_string += "Kusto results: redo_stats.avg " + str(run.result.failover_kusto_test[0]) + " failover_time_stats.max " + str(run.result.failover_kusto_test[1]) + "\n" 

                print("Kusto results: backup_duration_min " + str(run.result.backup_kusto_test))
                log_string += "Kusto results: backup_duration_min " + str(run.result.backup_kusto_test) + "\n"

                results.append(run)

                print("printing result for scheduled_benchmark_id " + str(run.scheduled_benchmark_id) + "\n" + str(run.result))
                log_string += "printing result for scheduled_benchmark_id " + str(run.scheduled_benchmark_id) +"\n" + str(run.result) + "\n"

                if(run.result.successful_run):
                    print("I have all results for this run: " + str(run.run_id))
                    log_string += "I have all results for this run: " + str(run.run_id) + "\n"

                    successful_runs.append(run)

                else:
                    print("Results are not here for run: " + str(run.run_id))
                    log_string += "Results are not here for run: " + str(run.run_id) + "\n"

            else:
                if CLperfDB.is_benchmark_picked_up(run):
                    print("run id" + str(run.run_id) + " is picked up, but not finished")
                    log_string += "run id" + str(run.run_id) + " is picked up, but not finished" + "\n"

                else:
                    print("scheduled benchmark id " + str(run.scheduled_benchmark_id) + " is not picked up")
                    log_string += "scheduled benchmark id " + str(run.scheduled_benchmark_id) + " is not picked up" + "\n"

        new_pending_runs = []
        for run in pending_runs:
            if CLperfDB.is_benchmark_picked_up(run) and CLperfDB.instance_state(connection, run.server_name) == 'Ready' and run.run_id is None:
                print("Run with schedule benchmark id" + str(run.scheduled_benchmark_id) + 'failed, due to setup or docker problems')
                log_string += "Run with schedule benchmark id" + str(run.scheduled_benchmark_id) + 'failed, , due to setup or docker problems' + '\n'
                failed_runs.append(run)
                CLperfDB.cancel_pending_actions_when_run_fails(run)
                continue
            
            if run.result is None:
                new_pending_runs.append(run)
            #ovo bi mozda trebalo izbaciti, jer nisam sigurna kad se ovo desava    
            if run.result is not None and not run.result.successful_run():
                new_pending_runs.append(run)

        if len(new_pending_runs) == len(pending_runs):
            changes = False
        else:
            changes = True

        pending_runs = new_pending_runs

        #exporting current situation to plot and .csv file if there is changes
        if changes:

            #ploting purposes
            successful_result_objects = [successful_run.result for successful_run in successful_runs]
            #generating data purposes
            all_result_objects = [res.result for res in results]
            failed_results_objects = [failed_run.result for failed_run in failed_runs]

            print("Exporting results - plotting")
            log_string += "Exporting results - plotting" + "\n"
            plot.export_results(successful_result_objects)

            print("Exporting results - csv")
            log_string += "Exporting results - csv" + "\n"
            common_functions.export_dataframe(Result.results_to_data_frame(all_result_objects), 'all')
            common_functions.export_dataframe(Result.results_to_data_frame(successful_result_objects), 'success')
            
            #exporting failed runs to dataframe
            #common_functions.export_dataframe(Result.results_to_data_frame(failed_results_objects), 'fail')
            common_functions.export_dataframe(pd.DataFrame([vars(failed_run) for failed_run in failed_runs]), 'fail')

        number_of_scheduled_benchmarks += len(runs)
        log_file = open("Logs/" + "log" + common_functions.current_timestamp() + ".txt", "w+")
        log_file.write(log_string)
        log_file.close()



