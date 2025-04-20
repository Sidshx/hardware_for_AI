import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# -----------------------
# 1) Sigmoid + Perceptron Rule
# -----------------------
def sigmoid(z):
    return 1 / (1 + np.exp(-z))

def sigmoid_derivative(y):
    # derivative of sigmoid if y = sigmoid(z)
    return y * (1 - y)

def forward(x, w, b):
    return sigmoid(np.dot(w, x) + b)

def perceptron_update(x, target, w, b, lr):
    """
    x:   input vector [x1, x2]
    target: scalar (0 or 1)
    w:   current weight vector
    b:   current bias
    lr:  learning rate
    """
    # Forward pass
    y = forward(x, w, b)
    error = target - y
    delta = error * sigmoid_derivative(y)
    
    # Update rule
    w[0] += lr * delta * x[0]
    w[1] += lr * delta * x[1]
    b    += lr * delta
    
    return w, b

# -----------------------
# 2) Data Setup (NAND) 
#    You can switch to e.g. AND or OR if you prefer
# -----------------------
X = np.array([
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
])
# NAND labels: only (1,1) -> 0
T = np.array([1, 1, 1, 0])

# -----------------------
# 3) Collect Weight/Bias at each step for animation
# -----------------------
def train_and_collect_updates(X, T, epochs=5, lr=0.1):
    """
    We'll do multiple epochs, 
    but store (w, b) after every single update 
    to animate the boundary.
    """
    # Random init
    w = np.random.randn(2)
    b = np.random.randn()
    
    # We'll store a list of (w, b) after each update
    wb_history = [(w.copy(), b)]
    
    for epoch in range(epochs):
        for x, t in zip(X, T):
            w, b = perceptron_update(x, t, w, b, lr)
            wb_history.append((w.copy(), b))
    return wb_history

epochs = 200
learning_rate = 0.1
wb_history = train_and_collect_updates(X, T, epochs=epochs, lr=learning_rate)

# -----------------------
# 4) Prepare for Animation
# -----------------------
# Setup the figure and axis
fig, ax = plt.subplots()
ax.set_xlim(-0.5, 1.5)
ax.set_ylim(-0.5, 1.5)
ax.set_xlabel('x1')
ax.set_ylabel('x2')
ax.set_title('Perceptron Decision Boundary (NAND)')

# Plot the data points. 
# We'll color by label: Red for 0, Blue for 1 (or pick your markers).
for i, x in enumerate(X):
    if T[i] == 0:
        ax.plot(x[0], x[1], 'ro', markersize=8, label='label=0' if i == 0 else "")
    else:
        ax.plot(x[0], x[1], 'bo', markersize=8, label='label=1' if i == 1 else "")

ax.legend(loc='best')

# We'll plot the line as we update. We'll create an empty line object first:
line, = ax.plot([], [], 'k-', linewidth=2)  # black line

def animate(frame_index):
    """This function updates the line for a given frame."""
    w, b = wb_history[frame_index]
    
    # If w2 is near zero, the slope becomes huge. We can handle that or skip plotting.
    if abs(w[1]) < 1e-5:
        # Just draw a vertical line if w2 ~ 0
        # w1 * x1 + w2 * x2 + b = 0  => x1 = -b / w1
        x1 = -b / w[0] if abs(w[0]) > 1e-5 else 0
        line.set_xdata([x1, x1])
        line.set_ydata([-0.5, 1.5])  # full vertical range
    else:
        # x2 = -(w1/w2)x1 - b/w2
        x_vals = np.array([-0.5, 1.5])
        y_vals = -(w[0]/w[1])*x_vals - b/w[1]
        line.set_xdata(x_vals)
        line.set_ydata(y_vals)
    
    ax.set_title(f'Perceptron Boundary (update #{frame_index})')
    return line,

ani = FuncAnimation(
    fig,
    animate,
    frames=len(wb_history),   # total frames is number of updates
    interval=500,            # milliseconds between frames
    blit=False,
    repeat=False
)

plt.show()

