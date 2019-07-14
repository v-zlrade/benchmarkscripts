"""
tag_settings --> <Instance><MaxWorkerThreads>1234</MaxWorkerThreads><MaxLogRate>567890</MaxLogRate></Instance>
dict_settings -->  dictionary of overrides
settings -> string(dict_settings)
"""
import json
import re

class Instance_Settings_Override(object):

    override_type = "Instance"
    constraints = {}

    def __init__(self,
                tag_settings): #tags
        self.tag_settings = tag_settings
        self.dict_settings = self.tag_to_dict()
        self.settings = json.dumps(self.dict_settings)
        #TBD: add for each parameter

    def __str__(self):
        return self.tag_settings

    """
    receives tag as string and returns dictionary
    <key>value</key>
    value contains number 
    """
    def tag_to_dict(self):
        #pattern_for_type = r"<(\w+)"
        pattern = r"<(.+)>(\d+)</\1>"
        #overrides_type = re.match(pattern_for_type, settings)[0]
        matches = re.findall(pattern, self.tag_settings)
        dict_settings = {}
        for match in matches:
            dict_settings[match[0]] = float(match[1])
        return dict_settings
        



    """
    inverse of instance_settings_to_dict
    recieves dictionary of instanse_overrides and 
    returns <key>value</key>
    """
    @staticmethod
    def dict_to_tag_static(dict_settings):
        res = '<' + 'Instance' + '>'
        for key, value in dict_settings.items():
            res += '<' + key + '>' + str(value) + '</' + key + '>'
        res += '</' + 'Instance' + '>'
        return res

    def dict_to_tag(self):
        return static_dict_to_tag_static(self)


    @staticmethod
    def set_constraints():
        with open("parameter_constraints.json", "r+") as parameter_constraints_file:
            Instance_Settings_Override.constraints = json.loads(parameter_constraints_file.read())

