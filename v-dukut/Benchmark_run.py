import json
import random
import CLperfDB
from Property_Overrides import Property_Overrides
from Config_Overrides import Config_Overrides
from Benchmark_Configs import Benchmark_Configs
from Result import Result

"""
Each benchmark run consists of benchmark configuration
    and instance configuration overrides including
    config params overrides, instance settings overrides,
    database settings overrides, slo property bag overrides
"""
class Benchmark_run(object):

    def __init__(self,
                connection,
                config_overrides, #object
                property_overrides, #object
                benchmark_configs,  #object
                server_name = None):
        
        self.connection = connection
        self.config_overrides = config_overrides
        self.property_overrides = property_overrides
        self.benchmark_configs = benchmark_configs

        #TBD take default server 
        if server_name is not None:
            self.benchmark_configs.server_name = server_name
            self.server_name = server_name
        else:
            self.server_name = benchmark_configs.server_name

        self.run_id = None
        self.scheduled_benchmark_id = None 
        self.is_picked_up = 0

        #Result object for benchmark results
        self.result = None

        #string, format %Y-%m-%d %H:%M:%s", example: "2019-06-05 07:40"
        self.start_time = None
        self.end_time = None
    
    def __str__(self):
        return "run_Id: " + str(self.run_id) + " scheduled id: " + str(self.scheduled_benchmark_id) + " Config Overrides: " + str(self.config_overrides) + " Property overrides: " + str(self.property_overrides) + "Benchmark configs: " + str(self.benchmark_configs)


    """
    read results from benchmark run
    [{"metric_name":"Transactions per minute","metric_value":188583.82},{"metric_name":"90th percentile","metric_value":0.51},{"metric_name":"Avg Success Ping Time (ms)","metric_value":2.87}]
    and converts to Result
    """
    def read_results(self, kusto_client):
        self.result = Result.read_result(benchmark_run= self, kusto_client= kusto_client)
    
    """
    {
    "InstanceConfigs":{"ConfigParamOverrides":{"ConfigNames":"names","ConfigValues":""},
    "InstanceSettingsOverrides":"<InstanceSettingsXML>","DatabaseSettingsOverrides":"<DatabaseSettingsXML>","SloPropertyBagOverrides":"<SloPropertyBagXML>","TraceFlags":""},
    "BenchmarkConfigs":{"BenchmarkName":"","ProcessorCount":,"IsBc":,"HardwareGeneration":"","Environment":"","ShouldRestore":,"Priority":,"WorkerNumber":,"BenchmarkScalingArgument":,"ScaledDown":,"Region":"","ServerName":"","DatabaseName":"","WarmupTimespanMinutes":,"RunTimespanMinutes":,"CustomMasterTSQLQuery":"","RequiredProcessorCount":,"ScheduledBy":"","Comment":""}
    }
    """
    def make_job_format(self):
        benchmark = {}

        benchmark["InstanceConfigs"] = {}
        benchmark["InstanceConfigs"]["ConfigParamOverrides"] = {}
        benchmark['BenchmarkConfigs'] = {}

        benchmark["InstanceConfigs"]["ConfigParamOverrides"]["ConfigNames"] = self.config_overrides.config_names
        benchmark["InstanceConfigs"]["ConfigParamOverrides"]["ConfigValues"] = self.config_overrides.config_values
        
        benchmark['InstanceConfigs']['InstanceSettingsOverrides'] = self.property_overrides.instance_settings
        benchmark['InstanceConfigs']['DatabaseSettingsOverrides'] = self.property_overrides.database_settings
        benchmark['InstanceConfigs']['SloPropertyBagOverrides'] = self.property_overrides.slo_property_bag

        benchmark['BenchmarkConfigs']['BenchmarkName'] = self.benchmark_configs.action_name
        benchmark['BenchmarkConfigs']['ProcessorCount'] = self.benchmark_configs.processor_count
        benchmark['BenchmarkConfigs']['IsBc'] = self.benchmark_configs.is_bc
        benchmark['BenchmarkConfigs']['HardwareGeneration'] = self.benchmark_configs.hardware_generation
        benchmark['BenchmarkConfigs']['Environment'] = self.benchmark_configs.environment

        if self.benchmark_configs.should_restore is not None:
            benchmark['BenchmarkConfigs']['ShouldRestore'] = self.benchmark_configs.should_restore        
        if self.benchmark_configs.priority is not None:
            benchmark['BenchmarkConfigs']['Priority'] = self.benchmark_configs.priority
        if self.benchmark_configs.worker_number is not None:    
            benchmark['BenchmarkConfigs']['WorkerNumber'] = self.benchmark_configs.worker_number
        if self.benchmark_configs.benchmark_scaling_argument is not None:
            benchmark['BenchmarkConfigs']['BenchmarkScalingArgument'] = self.benchmark_configs.benchmark_scaling_argument
        if self.benchmark_configs.scaled_down is not None:
            benchmark['BenchmarkConfigs']['ScaledDown'] = self.benchmark_configs.scaled_down
        if self.benchmark_configs.server_name is not None:
            benchmark['BenchmarkConfigs']['ServerName'] = self.benchmark_configs.server_name
        if self.benchmark_configs.database_name is not None:
            benchmark['BenchmarkConfigs']['DatabaseName'] = self.benchmark_configs.database_name
        if self.benchmark_configs.warmup_timespan_minutes is not None:
            benchmark['BenchmarkConfigs']['WarmupTimespanMinutes'] = self.benchmark_configs.warmup_timespan_minutes
        if self.benchmark_configs.run_timespan_minutes is not None:
            benchmark['BenchmarkConfigs']['RunTimespanMinutes'] = self.benchmark_configs.run_timespan_minutes
        if self.benchmark_configs.custom_master_tsql_query is not None:
            benchmark['BenchmarkConfigs']['CustomMasterTSQLQuery'] = self.benchmark_configs.custom_master_tsql_query
        if self.benchmark_configs.required_processor_count is not None:
            benchmark['BenchmarkConfigs']['RequiredProcessorCount'] = self.benchmark_configs.required_processor_count
        if self.benchmark_configs.comment is not None:
            benchmark['BenchmarkConfigs']['Comment'] = self.benchmark_configs.comment
        if self.benchmark_configs.scheduled_by is not None:
            benchmark['BenchmarkConfigs']['ScheduledBy'] = self.benchmark_configs.scheduled_by


        return json.dumps(benchmark), benchmark


    @staticmethod
    def make_run_from_given_configs(connection, config_overrides_object, property_overrides_object, benchmark_configs_object):
        return Benchmark_run(connection, config_overrides_object, property_overrides_object, benchmark_configs_object)


    @staticmethod
    def make_random_run(connection, benchmark_configs_object):
        config_overrides_object = Config_Overrides.choose_random_config_overrides()
        property_overrides_object = Property_Overrides.choose_random_property_overrides()

        return Benchmark_run(connection, config_overrides_object, property_overrides_object, benchmark_configs_object)
        

    @staticmethod
    def proccessed(run):
        if run.run_id is not None and run.end_time is not None:
            return True
        return False

    @staticmethod
    def not_proccessed(run):
        return not Benchmark_run.proccessed(run)

    def get_logical_server_name(self):
        return self.server_name.split('.')[0]