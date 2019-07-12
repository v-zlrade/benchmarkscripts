import numpy as np 

def fi(r):
    return r*r*r

def fi_matrix(x):
    size = x.shape[0]
    a = np.zeros((size, size))
    
    for i in range(size):
       for j in range(size):
            a.itemset((i,j), np.linalg.norm(x[i]-x[j]))
    return a



x = np.matrix('1 2 3; 4 5 6; 7 8 9; 10 11 12')
y = np.array([11, 29, 14, 52])
w = np.zeros(x.shape[0])
a = fi_matrix(x)

def s(t):
    f = 0
    for k in range(x.shape[0]):
        f += w[k]*fi(np.linalg.norm(t-x[k]))
    return f

w = np.linalg.solve(a, y)

test = np.random.rand(4,3)
y_test = s(test)

print(y_test)
