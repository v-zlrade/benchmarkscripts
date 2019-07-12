import numpy as np

#x is vector, len = number of parameters
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


#x is matrix, in each row is parameters, number of rows is number of evaluations
def make_fi_matrix(x, radial_basis_function):
    size = x.shape[0]
    a = np.zeros((size, size))
    
    for i in range(size):
       for j in range(size):
            a.itemset((i,j), radial_basis_function(np.linalg.norm(x[i]-x[j])))
    return a

def f(x):
    return 2*x[0]*x[1]*x[2]

def calculate_aproximated_function(t, w, x, radial_basis_function):
    f = 0
    for k in range(x.shape[0]):
        f += w[k]*radial_basis_function(np.linalg.norm(t-x[k]))
    return f

def calculate_weights(x, y, radial_basis_function= cubic_rbf):
    a = make_fi_matrix(x, radial_basis_function)
    w = np.linalg.solve(a, y)
    return w

#x_test = np.random.rand(20, 3)
#print("test values")
#print(x_test)
#y_test = np.apply_along_axis(f, 1, x_test)
#w = calculate_weights(x_test, y_test, radial_basis_function= cubic_rbf)

#x_val = np.random.rand(5, 3)
#y_val_real = np.apply_along_axis(f, 1, x_val)
#y_val = np.apply_along_axis(func1d= calculate_aproximated_function, axis= 1, arr= x_val, w= w, x= x_test, radial_basis_function= cubic_rbf)

#print(y_val)
#print(y_val_real)