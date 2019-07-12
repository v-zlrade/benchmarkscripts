from Config_Overrides import Config_Overrides
from Property_Overrides import Property_Overrides
from Benchmark_Configs import Benchmark_Configs
from Benchmark_run import Benchmark_run
from Job import Job
import CLperfDB

config_overrides = Config_Overrides.choose_random_config_overrides()
property_overrides = Property_Overrides.choose_random_property_overrides()
benchmark_configs = Benchmark_Configs.default_run_server_name_only('clperftesting-gen5-bc8-loose24-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com')
connection = CLperfDB.connect()
run = Benchmark_run(connection, config_overrides, property_overrides, benchmark_configs)

print(run)

runs = [run]
job = Job(connection, 'Dubravka_external_schedule', runs, 'scheduling from Python')
success = CLperfDB.schedule_job(job)

print(success)