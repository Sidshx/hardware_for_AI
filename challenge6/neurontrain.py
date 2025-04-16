import numpy as np

def sigmoid(z):
    return 1.0/(1.0+np.exp(-z))

def sigmoid_derivative(y):
    return y * (1.0 - y)

def forward(x, w, b):
    z = np.dot(w,x) +b 
    return sigmoid(z)

def update_weights(x,t,y,w,b,lr):
    """
    x: inputs (array)
    t: target
    y: neuron output
    w: current weights
    b: current bias
    lr: learning rate
    """
    error = t-y
    delta = error * sigmoid_derivative(y)

    for i in range(len(w)):
        w[i] += lr*delta*x[i]

    b += lr*delta

    return w,b

def train_perceptron(X, T, epochs = 10000, lr= 0.1):
    """
    X: list of input vectors (each is np.array of shape (2,))
    T: list/array of target outputs, same length as X
    epochs: how many passes over the entire dataset
    lr: learning rate
    """
    w = np.random.randn(2)
    b = np.random.randn()

    for epoch in range(epochs):

        for x, t in zip(X,T):
            y=forward(x,w,b)
            w,b= update_weights(x,t,y,w,b,lr)

    return w,b

def test_perceptron(X,w,b):
    """
    X: list of input vectors
    w, b: trained parameters
    Returns the list of outputs
    """
    outputs = []
    for x in X:
        y=forward(x,w,b)
        outputs.append(y)
    return outputs

# =========================
# NAND
# =========================
X_nand = [np.array([0,0]), np.array([0,1]), np.array([1,0]), np.array([1,1])]
T_nand = [1, 1, 1, 0]
w_nand, b_nand = train_perceptron(X_nand, T_nand, epochs=10000, lr=0.1)
outputs_nand = test_perceptron(X_nand, w_nand, b_nand)
print("NAND results:")
for x, y in zip(X_nand, outputs_nand):
    print(f"Input={x}, Output={y:.4f}")

# =========================
# XOR
# =========================
X_xor = [np.array([0,0]), np.array([0,1]), np.array([1,0]), np.array([1,1])]
T_xor = [0, 1, 1, 0]
w_xor, b_xor = train_perceptron(X_xor, T_xor, epochs=10000, lr=0.1)
outputs_xor = test_perceptron(X_xor, w_xor, b_xor)
print("\nXOR results:")
for x, y in zip(X_xor, outputs_xor):
    print(f"Input={x}, Output={y:.4f}")

