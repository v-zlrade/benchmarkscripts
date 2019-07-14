import json
import traceback
import brain
import CLperfDB
from Benchmark_run import Benchmark_run

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
        benchmark_dict['Benchmarks'] = [benchmark_run.configs_json for benchmark_run in benchmark_runs]
        self.configs = json.dumps(benchmark_dict)

        self.params = (self.name, self.configs, self.description)

        self.definition_id = None
        self.scheduling_ids = [run.run_id for run in benchmark_runs]


    def __str__(self):
        return "Job id: " + str(self.job_id) + "\nDescription: " + self.description

    def __eq__(self, other):
        self.id == other.id

    def read_results(self):
        for benchmark_run in self.benchmark_runs:
            benchmark_run.read_results()

    @staticmethod
    def make_job_from_benchmark_runs(connection, job_name, benchmark_configs_json_list, description):
        benchmark_dict = {}
        benchmark_dict['Benchmarks'] = benchmark_configs_json_list
        return Job(connection= connection, name= 'No overrides', configs= json.dumps(benchmark_dict), description= "First job scheduled from Python")
