from jobs import Job
import re

"""
receives tag as string and returns dictionary
<key>value</key>
value contains number 
"""
def instance_settings_to_dict(xml):
    pattern = r"<(.+)>(\d+)</\1>" 
    matches = re.findall(pattern, xml)
    dict_to_return = {}
    for match in matches:
        dict_to_return[match[0]] = float(match[1])
    return dict_to_return

"""
Updating parameters
"""
def decide_for_next_job(connection, job, job_results):
    return Job(connection,"Dummier job" ,job.configs, "...")

