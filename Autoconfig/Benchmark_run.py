
"""
Each benchmark run consists of benchmark configuration
    and instance configuration overrides including
    config params overrides, instance settings overrides,
    database settings overrides, slo property bag overrides
"""
import json
import random
import CLperfDB
from Instance_Settings_Overrides import Instance_Settings_Override
from Target import Target

class Benchmark_run(object):

    def __init__(self,
                connection,
                configs): #string
        
        self.connection = connection
        self.configs = configs
        self.configs_json = json.loads(configs)
        
        #TBD keyError exc

        self.config_param_overrides_names = self.configs_json["InstanceConfigs"]["ConfigParamOverrides"]["ConfigNames"]
        self.config_param_overrides_values = self.configs_json["InstanceConfigs"]["ConfigParamOverrides"]["ConfigValues"]
    
        self.instance_settings_overrides_tag = self.configs_json["InstanceConfigs"]["InstanceSettingsOverrides"]
        self.instance_settings_overrides_object = Instance_Settings_Override(self.configs_json["InstanceConfigs"]["InstanceSettingsOverrides"])

        self.database_settings_overrides = self.configs_json["InstanceConfigs"]["DatabaseSettingsOverrides"]
        self.slo_propery_bag_overrides = self.configs_json["InstanceConfigs"]["SloPropertyBagOverrides"]
        self.trace_flags = self.configs_json["InstanceConfigs"]["TraceFlags"]

        self.custom_master_tsql_query = self.configs_json["BenchmarkConfigs"]["CustomMasterTSQLQuery"]
        self.benchmark_configs = self.configs_json["BenchmarkConfigs"]

        self.run_id = None
        #Target object for benchmark results
        self.target = None    
    
    def __str__(self):
        return "Id: " + str(self.run_id) + " Overrides: " + str(self.instance_settings_overrides_tag)


    """
    read results from benchmark run
    [{"metric_name":"Transactions per minute","metric_value":188583.82},{"metric_name":"90th percentile","metric_value":0.51},{"metric_name":"Avg Success Ping Time (ms)","metric_value":2.87}]
    and converts to Target
    """
    def read_results(self):
        results_json = CLperfDB.read_results_benchmark(self)
        self.target = Target(results_json_list, self.run_id)


    """
    sets random values for instance overrides (with appropriate constraints)
    """
    def choose_random_instance_override(self):
        new_overrides = {}
        for parameter_name, constraints in Instance_Settings_Override.constraints.items():
            new_overrides[parameter_name] = random.randint(constraints['minValue'], constraints['maxValue'] + 1)

        new_overrides_tag = Instance_Settings_Override.dict_to_tag_static(new_overrides)
        self.instance_settings_overrides_object = Instance_Settings_Override(new_overrides_tag)
        self.instance_settings_overrides_tag = new_overrides_tag
        self.configs_json["InstanceConfigs"]["InstanceSettingsOverrides"] = new_overrides_tag