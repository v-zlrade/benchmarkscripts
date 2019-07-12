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

train_file_name = sys.argv[1]
train_df = pd.read_csv('Analitics/' + train_file_name)
test_file_name = sys.argv[2]
test_df = pd.read_csv('Analitics/' + test_file_name)

train_max_outstanding_io = train_df['max_outstanding_io'].values
train_request_size_bytes = train_df['volume_io_request_size_bytes'].values
train_max_log_rate = train_df['max_log_rate'].values

test_max_outstanding_io = test_df['max_outstanding_io'].values
test_request_size_bytes = test_df['volume_io_request_size_bytes'].values
test_max_log_rate = test_df['max_log_rate'].values

x_test = np.column_stack((test_max_outstanding_io, test_request_size_bytes, test_max_log_rate))
x_train = np.column_stack((train_max_outstanding_io, train_request_size_bytes, train_max_log_rate))

weights_cubic = train_df['weights_cubic'].values
weights_linear = train_df['weights_linear'].values
#weights_gaussian = train_df['weights_gaussian'].values
weights_multiquadratic = train_df['weights_multiquadratic'].values

y_val_cubic = np.apply_along_axis(func1d= rbf.calculate_aproximated_function, axis= 1, arr= x_test, w= weights_cubic, x= x_train, radial_basis_function= cubic_rbf)
test_df.insert(4, "loss_val_cubic", y_val_cubic)

y_val_linear = np.apply_along_axis(func1d= rbf.calculate_aproximated_function, axis= 1, arr= x_test, w= weights_cubic, x= x_train, radial_basis_function= linear_rbf)
test_df.insert(4, "loss_val_linear", y_val_linear)

#y_val_gaussian = np.apply_along_axis(func1d= rbf.calculate_aproximated_function, axis= 1, arr= x_test, w= weights_cubic, x= x_train, radial_basis_function= gaussian_rbf)
#test_df.insert(4, "loss_val_gaussian", y_val_gaussian)

y_val_multiquadratic = np.apply_along_axis(func1d= rbf.calculate_aproximated_function, axis= 1, arr= x_test, w= weights_cubic, x= x_train, radial_basis_function= multiquadratic_rbf)
test_df.insert(4, "loss_val_multiquadratic", y_val_multiquadratic)

test_df.to_csv('Analitics/Approximated' + test_file_name)





