
import json, re, random

class Benchmark_Configs(object):

    def __init__(self,
                 action_name,
                 processor_count,
                 is_bc,
                 hardware_generation,
                 environment,
                 should_restore= None,
                 priority= None,
                 worker_number= None,
                 benchmark_scaling_argument= None,
                 scaled_down= None,
                 server_name= None,
                 database_name= None,
                 warmup_timespan_minutes= None,
                 run_timespan_minutes= None,
                 custom_master_tsql_query= None,
                 required_processor_count= None,
                 scheduled_by= None,
                 comment= None):

        self.action_name = action_name
        self.processor_count = processor_count
        self.is_bc = is_bc
        self.hardware_generation = hardware_generation
        self.environment = environment
        self.should_restore = should_restore
        self.priority = priority
        self.worker_number = worker_number
        self.benchmark_scaling_argument = benchmark_scaling_argument
        self.scaled_down = scaled_down
        self.server_name = server_name
        self.database_name = database_name
        self.warmup_timespan_minutes = warmup_timespan_minutes
        self.run_timespan_minutes = run_timespan_minutes
        self.custom_master_tsql_query = custom_master_tsql_query
        self.required_processor_count = required_processor_count
        self.scheduled_by = scheduled_by
        self.comment = comment

    def __str__(self):
        return self.action_name + " warmup:" + str(self.warmup_timespan_minutes) + "run: " + str(self.run_timespan_minutes) + " database: " + str(self.database_name)

    #for test
    @staticmethod
    def default_run_server_name_only(server_name):
        return Benchmark_Configs(action_name = "TPCC",
                                             processor_count = 8,
                                             is_bc = 1,
                                             hardware_generation = "SVMLoose",
                                             environment = "SVMStage",
                                             should_restore = 0,
                                             priority = 100,
                                             worker_number = 100,
                                             benchmark_scaling_argument = 10500,
                                             scaled_down = 1,
                                             server_name = server_name,
                                             database_name = "tpcc10500",
                                             warmup_timespan_minutes = 1,
                                             run_timespan_minutes = 5,
                                             custom_master_tsql_query = "",
                                             required_processor_count = 15,
                                             scheduled_by = "v-dukut",
                                             comment = "Random benchmark run")



    @staticmethod
    def make_run(instance_info):

        server_name = instance_info['instance_name']
        processor_count = instance_info['processor_count']
        is_bc = instance_info['is_bc']
        hardware_generation = instance_info['hardware_generation']
        environment = instance_info['environment']  

        #benchmark_configuration_for_all_runs

        benchmark_json = open('Configurations/benchmark_configs.json', 'r+').read()
        benchmark = json.loads(benchmark_json)

        action_name = benchmark["BenchmarkName"]
        priority = benchmark["Priority"]
        should_restore = benchmark["ShouldRestore"]
        benchmark_scaling_argument = benchmark["BenchmarkScalingArgument"]
        scaled_down = benchmark["ScaledDown"]
        database_name = benchmark["DatabaseName"]
        warmup_timespan_minutes = benchmark["WarmupTimespanMinutes"]
        run_timespan_minutes = benchmark["RunTimespanMinutes"]
        required_processor_count = benchmark["RequiredProcessorCount"]
        scheduled_by = benchmark["ScheduledBy"]
        comment = benchmark["Comment"]

        return Benchmark_Configs(action_name= action_name, processor_count= processor_count, is_bc= is_bc, hardware_generation= hardware_generation, environment= environment, should_restore= should_restore,
                        priority= priority, benchmark_scaling_argument= benchmark_scaling_argument, scaled_down= scaled_down,
                        server_name= server_name, database_name= database_name, warmup_timespan_minutes= warmup_timespan_minutes, run_timespan_minutes= run_timespan_minutes,
                        required_processor_count= required_processor_count, scheduled_by= scheduled_by, comment = comment)
