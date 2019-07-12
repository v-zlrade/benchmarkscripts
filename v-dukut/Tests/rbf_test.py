import numpy as np
import matplotlib.pyplot as plt

def cube(x):
    return x*x*x

def exp(x):
    return np.exp(-10*(x*x))


x = np.linspace(-10, 10)
y = cube(x)
z = exp(x)

plt.plot(x,y)
plt.show()

plt.plot(x,z)
plt.show()