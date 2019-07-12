from Benchmark_Configs import Benchmark_Configs
import json

instances_json = open('Configurations/instances.json', 'r+').read()
instances = json.loads(instances_json)

print(instances)