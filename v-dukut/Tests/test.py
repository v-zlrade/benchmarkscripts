a = '[{"metric_name":"Transactions per minute","metric_value":188583.82},{"metric_name":"90th percentile","metric_value":0.51},{"metric_name":"Avg Success Ping Time (ms)","metric_value":2.87}]'
from Job import Job
from Benchmark_run import Benchmark_run
from Property_Overrides import Property_Overrides
from Config_Overrides import Config_Overrides
from Benchmark_Configs import Benchmark_Configs
from Target import Target
import brain
import CLperfDB
import json

#con = CLperfDB.connect()
#run1 = open("benchmark_run.json","r").read()
#brun1 = Benchmark_run(con, run1)
#run2 = open("benchmark_run.json","r").read()
#brun2 = Benchmark_run(con, run2)
#lista = [brun1, brun2]

#a = {}
#a['SQL.Config_RgSettings_MaxOutstandingIo'] = 256
#a['SQL.Config_RgSettings_LocalVolumeMaxOutstandingIo'] = 256
#a['SQL.Config_RgSettings_LocalVolumeIORequestSizeBytes'] = 65536

#names, values = Config_overrides.dict_to_space(a)

#print('pocetak'+names+'kraj')
#print('pocetak'+values+'kraj')

#a_back = Config_overrides.space_to_dict(names, values)

#print(a_back)

#con = CLperfDB.connect()
#instance_name = 'clperftesting-gen5-bc8-loose24-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com'

#state = CLperfDB.instance_state(con, instance_name)
#print("Instance state is " + str(state))

#Property_Overrides.set_instance_constraints()
#Property_Overrides.set_database_constraints()
#Property_Overrides.set_slopropertybag_constraints()

#instance_overrides = Property_Overrides.choose_random_instance_overrides()
#database_overrides = Property_Overrides.choose_random_database_overrides()
#sloproperty_overrides = Property_Overrides.choose_random_slopropertybag_overrides()

#print('instance_overrides' + instance_overrides)
#print('database_overrides' + database_overrides)
#print('sloproperty_overrides' + sloproperty_overrides)

#overrides = Property_Overrides(instance_overrides, database_overrides, sloproperty_overrides)

#print(overrides)

#Config_overrides.set_constraints()
#config_names, config_values = Config_overrides.choose_random_config_overrides()

#print(config_names)
#print(config_values)

#overrides = Config_overrides(config_names, config_values)

#print(overrides)


con = CLperfDB.connect()

config = {}
config['SQL.Config_RgSettings_LocalVolumeMaxOutstandingIo'] = 256
config['SQL.Config_RgSettings_MaxOutstandingIo'] = 256
config['SQL.Config_RgSettings_LocalVolumeIORequestSizeBytes'] = 65536

instance_settings = '<Instance><MaxLogRate>100663296</MaxLogRate></Instance>'
database_settings = ''
slo_property_bag = '<SloRgMapping><primary><group_log_rate_max>100663296</group_log_rate_max><pool_log_rate_max_bps>100663296</pool_log_rate_max_bps></primary></SloRgMapping>'

config_names, config_values = Config_Overrides.dict_to_space(config)

config_object = Config_Overrides(config_names, config_values)
property_object = Property_Overrides(instance_settings, database_settings, slo_property_bag)
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


run = Benchmark_run(con, config_object, property_object, benchmark_configs_object)
#for_scheduling = run.make_job_format()
runs = [run]

#print(run.make_job_format())

job = Job(con, 'Python2', runs, 'scheduling from Python')

CLperfDB.schedule_job(job)

print(job.id)