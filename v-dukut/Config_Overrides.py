import re
import json
import random

class Config_Overrides(object):

    constraints = {}

    def __init__(self,
                 config_names, #string "param1 param2 .."
                 config_values): #string "(val1) (val2) .."

        #paramaters for scheduling
        self.config_names = config_names
        self.config_values = config_values

        #parameters for internal use (dictionary: key=config_name, value=config_value)
        names_list = re.split(" ", config_names)
        values_list = re.split(" ", config_values)

        self.config_dict = {}

        for name, value in zip(names_list, values_list):
            self.config_dict[name] = int(value)


    def __str__(self):
        return str(self.config_dict)


    @staticmethod
    def dict_to_space(config_dict):
        config_names = ""
        for name in config_dict:
            config_names += name + " "       
        config_names = config_names[:-1]

        config_values = ""
        for value in config_dict.values():
            config_values += str(value) + " "
        config_values = config_values[:-1]

        return config_names, config_values

    @staticmethod
    def space_to_dict(config_names, config_values):
        config_names_list = re.split(" ",config_names)
        config_values_list = re.split(" ",config_values)

        config_dict = {}

        for name, value in zip(config_names_list,config_values_list ):
            config_dict[name] = int(value)

        return config_dict

    
    @staticmethod
    def set_constraints():
        with open("Configurations/config_parameters_constraints.json", "r+") as parameter_constraints_file:
            Config_Overrides.constraints = json.loads(parameter_constraints_file.read())

    """
    sets random values for config overrides (with appropriate constraints given in config_overrides_parameters_constraints)
    """
    @staticmethod
    def choose_random_config_overrides():
        Config_Overrides.set_constraints()
        new_overrides = {}
        for parameter_name, constraints in Config_Overrides.constraints.items():

            if 'equals' in constraints:
                new_overrides[parameter_name] = new_overrides[constraints['equals']]
            else:
                new_overrides[parameter_name] = random.randint(int(constraints['minValue']/constraints['gridSize']), int((constraints['maxValue'] + 1)/constraints['gridSize']))*constraints['gridSize']

        config_names, config_values = Config_Overrides.dict_to_space(new_overrides)
        
        #return config_names, config_values
        return Config_Overrides(config_names, config_values)