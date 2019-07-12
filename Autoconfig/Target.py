"""
Represents metrics that we want to optimize
"""
WEIGHTS = [1,1] #hyperparameters - to be decided priorly 

class Target(object):
    def __init__(self,
                 results_json_list,
                 run_id):

        for metric_index in len(results_json_list):
            self.dict[results_json_list[metric_index]['metric_name']] = results_json_list[metric_index]['metric_name']

        self.transactions_per_minute = self.dict['Transactions per minute']
        self.response_time = self.dict['90th percentile']
        self.avg_success_ping_time_in_ms = self.dict['Avg Success Ping Time (ms)']

        self.run_id = run_id

    def __lt__(self, other):
        return calculate_loss(self, WEIGHTS) > calculate_loss(other, WEIGHTS)
        
    def calculate_loss(self, weigths):
        return WEIGHTS[0] * self.transactions_per_minute + WEIGHTS[1] * (self.response_time < 1)
