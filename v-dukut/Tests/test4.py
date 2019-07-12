from azure.kusto.data.request import KustoClient, KustoConnectionStringBuilder
from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data.helpers import dataframe_from_result_table
from Benchmark_run import Benchmark_run
from Benchmark_Configs import Benchmark_Configs
import KustoFailover
import CLperfDB

cluster_name = "https://sqlstage.kustomfa.windows.net"
kcsb = KustoConnectionStringBuilder.with_aad_device_authentication(cluster_name)
client = KustoClient(kcsb)

connection = CLperfDB.connect()

benchmark_configs_object = Benchmark_Configs(action_name = "TPCC",
                                             processor_count = 8,
                                             is_bc = 1,
                                             hardware_generation = "SVMLoose",
                                             environment = "SVMStage",
                                             should_restore = 0,
                                             priority = 100,
                                             worker_number = 100,
                                             benchmark_scaling_argument = 10500,
                                             scaled_down = 1,
                                             server_name = "clperftesting-gen5-bc8-loose24-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com",
                                             database_name = "tpcc10500",
                                             warmup_timespan_minutes = 1,
                                             run_timespan_minutes = 5,
                                             custom_master_tsql_query = "",
                                             required_processor_count = 15,
                                             scheduled_by = "v-dukut",
                                             comment = "Scheduled from python")

run = Benchmark_run.make_random_run(connection, benchmark_configs_object)
run.scheduled_benchmark_id = 4257

result = KustoFailover.failover_kusto_test_fails(client, run)

print(result)