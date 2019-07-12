import CLperfDB
from Property_Overrides import Property_Overrides
from Config_Overrides import Config_Overrides
from Benchmark_run import Benchmark_run
from Benchmark_Configs import Benchmark_Configs
from Job import Job

con = CLperfDB.connect()

#instance_settings = Property_Overrides.choose_random_instance_overrides()
#database_settings = Property_Overrides.choose_random_database_overrides()
#slo_property_bag = Property_Overrides.choose_random_slopropertybag_overrides()
#config_names, config_values = Config_Overrides.choose_random_config_overrides()

#config_object = Config_Overrides(config_names, config_values)
#property_object = Property_Overrides(instance_settings, database_settings, slo_property_bag)
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

#run = Benchmark_run.make_run_from_given_configs(con, config_object, property_object, benchmark_configs_object)
run = Benchmark_run.make_random_run(con, benchmark_configs_object)
runs = [run]

job = Job(con, 'Python4', runs, 'scheduling from Python')

success = CLperfDB.schedule_job(job)

print(success)