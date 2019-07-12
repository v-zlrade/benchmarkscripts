"""
tag_settings --> <Instance><MaxWorkerThreads>1234</MaxWorkerThreads><MaxLogRate>567890</MaxLogRate></Instance>
dict_settings -->  dictionary of overrides
settings -> string(dict_settings)
"""
import json
import re
import random

class Property_Overrides(object):
    instance_constraints = {}
    database_constraints = {}
    slopropertybag_constraints = {}
    constraints = {}

    def __init__(self,
                 instance_settings, #string <...>
                 database_settings, #string <...>
                 slo_property_bag): #string <...>

        #paramaters for scheduling
        self.instance_settings = instance_settings
        self.database_settings = database_settings
        self.slo_property_bag = slo_property_bag

        #parameters for internal use
        self.instance_settings_dict = Property_Overrides.tag_to_dict(instance_settings)
        self.databasev_settings_dict = Property_Overrides.tag_to_dict(database_settings)
        self.slo_property_bag_dict = Property_Overrides.tag_to_dict(slo_property_bag)


    def __str__(self):
        return "InstanceSettings: " + self.instance_settings  + "DatabaseSettings: " + self.database_settings + "SloPropertyBag: " + self.slo_property_bag

    """
    receives tag as string and returns dictionary
    <key>value</key>
    value contains number 
    """
    @staticmethod
    def tag_to_dict(tags):
        #pattern_for_type = r"<(\w+)"
        pattern = r"<(.+)>(\d+)</\1>"
        #overrides_type = re.match(pattern_for_type, settings)[0]
        matches = re.findall(pattern, tags)
        dict_settings = {}
        for match in matches:
            dict_settings[match[0]] = float(match[1])
        return dict_settings

    """
    inverse of instance_settings_to_dict
    recieves dictionary of instanse_overrides and 
    returns <key>value</key>
    This definitely does not work for slo property bag since it has primary tag
    """
    @staticmethod
    def dict_to_tag(dict_settings, main_tag, additional_tag = ""):

        #in case of slo property bag, I need primary tag also
        #I want that additional_open_tag (additional_close_tag) is "" or <primary>
        if additional_tag:
           additional_open_tag = '<'+ additional_tag +'>'
           additional_close_tag = '</' + additional_tag +'>'
        else: 
            additional_open_tag = ''
            additional_close_tag = ''

        res = '<' + main_tag + '>' + additional_open_tag
        for key, value in dict_settings.items():
            res += '<' + key + '>' + str(value) + '</' + key + '>'
        res += additional_close_tag + '</' + main_tag + '>'
        return res


    @staticmethod
    def set_instance_constraints():
        with open("instance_parameters_constraints.json", "r+") as parameter_constraints_file:
            Property_Overrides.instance_constraints = json.loads(parameter_constraints_file.read())

    @staticmethod
    def set_database_constraints():
        with open("database_parameters_constraints.json", "r+") as parameter_constraints_file:
            Property_Overrides.database_constraints = json.loads(parameter_constraints_file.read())

    @staticmethod
    def set_slopropertybag_constraints():
        with open("slopropertybag_parameters_constraints.json", "r+") as parameter_constraints_file:
            Property_Overrides.slopropertybag_constraints = json.loads(parameter_constraints_file.read())

    @staticmethod
    def set_constraints():
        with open("Configurations/property_parameters_constraints.json", "r+") as parameter_constraints_file:
            Property_Overrides.constraints = json.loads(parameter_constraints_file.read())
            
    """
    sets random values for instance property overrides (with appropriate constraints given in instance_parameters_constraints)
    """
    @staticmethod
    def choose_random_instance_overrides():
        Property_Overrides.set_instance_constraints()
        new_overrides = {}
        for parameter_name, constraints in Property_Overrides.instance_constraints.items():
            new_overrides[parameter_name] = random.randint(constraints['minValue'], constraints['maxValue'] + 1)

        return Property_Overrides.dict_to_tag(new_overrides, 'Instance')

    """
    sets random values for database property overrides (with appropriate constraints given in database_overrides_parameters_constraints)
    """
    @staticmethod
    def choose_random_database_overrides():
        
        #Property_Overrides.set_database_constraints()
        #new_overrides = {}
        #for parameter_name, constraints in Property_Overrides.database_constraints.items():
        #    new_overrides[parameter_name] = random.randint(constraints['minValue'], constraints['maxValue'] + 1)

        #return Property_Overrides.dict_to_tag(new_overrides, 'Database')
        
        return ""
    
    """
    sets random values for slo property bag overrides (with appropriate constraints given in slopropertybag_parameters_constraints)
    """
    @staticmethod
    def choose_random_slopropertybag_overrides():
        Property_Overrides.set_slopropertybag_constraints()
        new_overrides = {}
        for parameter_name, constraints in Property_Overrides.slopropertybag_constraints.items():
            new_overrides[parameter_name] = random.randint(constraints['minValue'], constraints['maxValue'] + 1)

        return Property_Overrides.dict_to_tag(new_overrides, 'SloRgMapping', additional_tag= 'primary')

    @staticmethod
    def choose_random_property_overrides():
        #instance_settings = Property_Overrides.choose_random_instance_overrides()
        #database_settings = Property_Overrides.choose_random_database_overrides()
        #slo_property_bag = Property_Overrides.choose_random_slopropertybag_overrides()

        Property_Overrides.set_constraints()
        new_overrides = {}
        for parameter_name, constraints in Property_Overrides.constraints.items():
            if 'equals' in constraints:
                new_overrides[parameter_name] = new_overrides[constraints['equals']]
            else:
                new_overrides[parameter_name] = random.randint(int(constraints['minValue']/constraints['gridSize']), int((constraints['maxValue'] + 1)/constraints['gridSize']))*constraints['gridSize']

        instance_settings_dict = {}
        sloproperty_bag_dict = {}

        for parameter_name, constraints in Property_Overrides.constraints.items():
            if 'type' in constraints:
                if constraints['type'] == 'Instance':
                    instance_settings_dict[parameter_name] = new_overrides[parameter_name]
                if constraints['type'] == 'SloRgMapping':
                    sloproperty_bag_dict[parameter_name] = new_overrides[parameter_name]

        instance_settings = Property_Overrides.dict_to_tag(instance_settings_dict, 'Instance')
        slo_property_bag = Property_Overrides.dict_to_tag(sloproperty_bag_dict, 'SloRgMapping', additional_tag= 'primary')

        return Property_Overrides(instance_settings= instance_settings, database_settings= "", slo_property_bag= slo_property_bag)

        #return Property_Overrides(instance_settings, database_settings, slo_property_bag)