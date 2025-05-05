#!/usr/bin/env python
import numpy as np
import time

# --- 1) Define the example HMM ---
A = np.array([[0.8, 0.1, 0.1],
              [0.2, 0.7, 0.1],
              [0.1, 0.3, 0.6]])
C = np.array([0.6, 0.2, 0.2])
B = np.array([[0.7, 0.0, 0.3],
              [0.1, 0.9, 0.0],
              [0.0, 0.2, 0.8]])

# Precompute log-domain matrices to avoid underflow
logA = np.log(A + 1e-12)
logC = np.log(C + 1e-12)
logB = np.log(B + 1e-12)

# --- 2) Sequence generation ---
def generate_sequence_hmm(N, A, C, B):
    I, K = A.shape[0], B.shape[1]
    O = np.zeros(N, int)
    S = np.zeros(N, int)
    for n in range(N):
        if n == 0:
            i = np.random.choice(I, p=C)
        else:
            i = np.random.choice(I, p=A[i])
        k = np.random.choice(K, p=B[i])
        S[n], O[n] = i, k
    return O, S

# --- 3) Log-domain Forward algorithm ---
def forward_log(O, logA, logC, logB):
    N, I = len(O), logA.shape[0]
    alpha = np.full((N, I), -np.inf)
    alpha[0] = logC + logB[:, O[0]]
    for n in range(1, N):
        for j in range(I):
            prev = alpha[n-1] + logA[:, j]
            m = np.max(prev)
            alpha[n, j] = m + np.log(np.sum(np.exp(prev - m)))
        alpha[n] += logB[:, O[n]]
    last = alpha[-1]
    m = np.max(last)
    logP = m + np.log(np.sum(np.exp(last - m)))
    return alpha, logP

# --- 4) Viterbi algorithm (log-domain) ---
def viterbi(O, A, C, B):
    N, I = len(O), A.shape[0]
    delta = np.zeros((N, I))
    psi   = np.zeros((N, I), int)
    delta[0] = np.log(C + 1e-12) + np.log(B[:, O[0]] + 1e-12)
    for n in range(1, N):
        for j in range(I):
            seq = delta[n-1] + np.log(A[:, j] + 1e-12)
            psi[n, j]   = np.argmax(seq)
            delta[n, j] = seq[psi[n, j]] + np.log(B[j, O[n]] + 1e-12)
    S_hat = np.zeros(N, int)
    S_hat[-1] = np.argmax(delta[-1])
    for n in range(N-2, -1, -1):
        S_hat[n] = psi[n+1, S_hat[n+1]]
    return S_hat, np.max(delta[-1])

# --- 5) Scaling experiment ---
def main():
    np.random.seed(42)
    print("   N     | Log P[O|Θ]    | Viterbi (s)")
    print("---------+---------------+--------------")
    for N in [10_000, 50_000, 100_000, 200_000, 500_000]:
        O, _ = generate_sequence_hmm(N, A, C, B)

        t0 = time.perf_counter()
        _, logp_O = forward_log(O, logA, logC, logB)
        t1 = time.perf_counter()
        _, logp_S = viterbi(O, A, C, B)
        t2 = time.perf_counter()

        print(f"{N:8d} | {logp_O:13.2f} | {t2-t1:12.3f}")

if __name__ == "__main__":
    main()

