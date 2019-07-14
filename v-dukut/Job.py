import json
import traceback
import CLperfDB
from Benchmark_run import Benchmark_run
import common_functions

"""
Job represents set of benchmarks. Each benchmark consists of its own
configuration. Job example:

{"Benchmarks":  [
    {
      "InstanceConfiguration":
      {
        "ConfigParamOverrides": {"ConfigNames":"", "ConfigValues":""}, #odgovara CAS akciji UpdateManagedServerConfigurationParameters
        "InstanceSettingsOverrides":  "<InstanceSettingsXML>" ,
        "DatabaseSettingsOverrides": "<DatabaseSettingsXML>",
        "SloPropertyBagOverrides": "<SloPropertyBagXML>",
        "TraceFlags": ""
      },
      "BenchmarkConfigs": {...}
    },
    {
      "InstanceConfiguration":
      {
        "ConfigParamOverrides": {"ConfigNames":"", "ConfigValues":""},
        "InstanceSettingsOverrides":  "<InstanceSettingsXML>" ,
        "DatabaseSettingsOverrides": "<DatabaseSettingsXML>",
        "SloPropertyBagOverrides": "<SloPropertyBagXML>",
        "TraceFlags": ""
      },
      "BenchmarkConfigs": {...}
    }
  ]
}

"""

class Job(object):

    def __init__(self,
                 connection,
                 name,
                 benchmark_runs, #list of Benchmark_run objects
                 description):
        
        self.connection = connection
        self.name = name
        self.benchmark_runs = benchmark_runs
        self.description = description

        benchmark_dict = {}

        benchmark_dict['Benchmarks'] = [benchmark_run.make_job_format()[1] for benchmark_run in benchmark_runs]

        self.configs = common_functions.single_to_double_quotes(json.dumps(benchmark_dict))

        self.params = (self.name, self.configs, self.description)

        self.definition_id = None #job_definitions table
        self.id = None #jobs table
        #we dont have this when scheduling
        #self.scheduling_ids = [run.run_id for run in benchmark_runs]

        self.scheduling_ids = None
        self.scheduled = False


    def __str__(self):
        return "Job id: " + str(self.id) + "\nDescription: " + self.description

    def __eq__(self, other):
        self.name == other.name

    def read_results(self):
        for benchmark_run in self.benchmark_runs:
            benchmark_run.read_results()

    #@staticmethod
    #def make_job_from_benchmark_runs(connection, job_name, benchmark_runs, description):
    #    benchmark_runs_list = [benchmark_run.make_job_format()[0] for benchmark_run in benchmark_runs]
#
 #       benchmark_dict = {}
  #      benchmark_dict['Benchmarks'] = benchmark_runs_list
   #     return Job(connection= connection, name= job_name, configs= json.dumps(benchmark_dict), description= description)

    def make_benchmark_runs_json_list(self):
        return [benchmark_run.make_job_format()[0] for benchmark_run in self.benchmark_runs]
