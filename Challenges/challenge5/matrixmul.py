import numpy as np

def matrix_multiplication(A, B):
	"""
	Perform matrix multiplication on two input matrices A and B.
	"""
	if A.shape[1] != B.shape[0]:
    	    raise ValueError("Number of columns in A must match the number of rows in B")
    
	C = np.dot(A, B)
	return C

# Example usage
if __name__ == "__main__":
	# Example matrices
	A = np.array([[1, 2], [3, 4]])
	B = np.array([[5, 6], [7, 8]])
    
	result = matrix_multiplication(A, B)
	print("Resultant Matrix:")
	print(result)

