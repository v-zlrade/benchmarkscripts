import rbf
import sys
import pandas as pd
import numpy as np

def cubic_rbf(r):
    eps = 1
    return eps*r*r*r

def linear_rbf(r):
    eps = 1
    return eps*r

def gaussian_rbf(r):
    eps = 1
    return np.exp(-np.power(eps*r,2)) 

def multiquadratic_rbf(r):
    eps = 1
    return np.sqrt(1+ np.power(eps*r, 2))

file_name = sys.argv[1]
df = pd.read_csv('Analitics/' + file_name)

max_outstanding_io = df['max_outstanding_io'].values
request_size_bytes = df['volume_io_request_size_bytes'].values
max_log_rate = df['max_log_rate'].values
x = np.column_stack((max_outstanding_io, request_size_bytes, max_log_rate))

y = df['loss'].values

weights_rbf_cubic = rbf.calculate_weights(x, y, cubic_rbf)

df.insert(4, "weights_cubic", weights_rbf_cubic)

weights_rbf_linear = rbf.calculate_weights(x, y, linear_rbf)
df.insert(4, "weights_linear", weights_rbf_linear)

#weights_rbf_gaussian = rbf.calculate_weights(x, y, gaussian_rbf)
#df.insert(4, "weights_gaussian", weights_rbf_gaussian)

weights_multiquadratic = rbf.calculate_weights(x, y, multiquadratic_rbf)
df.insert(4, "weights_multiquadratic", weights_multiquadratic)

df.to_csv('Analitics/Weighted' + file_name)


