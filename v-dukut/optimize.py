import numpy as np

def gradient_cubic_spline(x, data_points, weights):
    norms = []
    for point in data_points:
        norms.append(np.linalg.norm(x-point))
    norms = np.array(norms)
    derivative = np.zeros(3)

    for j in range(3):
        for i in range(data_points.shape[0]):
            derivative[j] += 3*weights[i]*np
            derivative[j] = 3*(x[i] - data_points[i][j])*np.sum(norms, weights)

def gradient_descent(f, grad, x, alpha, eps, max_iterations, data_points, weights):
    result = {}
    
    x_old = x 
    for i in range(max_iterations):
        x_new = x_old - alpha*grad(x_old, data_points, weights)
        if np.abs(f(x_new)-f(x_old))<eps:
            break
        x_old = x_new
    
    result['converge'] = i != max_iterations-1
    result['number_of_iterations'] = i
    result['x_min'] = x_old
    
    return result