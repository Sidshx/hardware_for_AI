#!/usr/bin/env python3
import numpy as np
import time
import cProfile, pstats, io

# --- 1) Define the example HMM ---
A = np.array([[0.8, 0.1, 0.1],
              [0.2, 0.7, 0.1],
              [0.1, 0.3, 0.6]])
C = np.array([0.6, 0.2, 0.2])
B = np.array([[0.7, 0.0, 0.3],
              [0.1, 0.9, 0.0],
              [0.0, 0.2, 0.8]])

# Precompute logs
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

# --- 3) Log-domain Forward ---
def forward_log(O, logA, logC, logB):
    N, I = len(O), logA.shape[0]
    alpha = np.full((N, I), -np.inf)
    alpha[0] = logC + logB[:, O[0]]
    for n in range(1, N):
        for j in range(I):
            prev = alpha[n-1] + logA[:, j]
            m    = np.max(prev)
            alpha[n, j] = m + np.log(np.sum(np.exp(prev - m)))
        alpha[n] += logB[:, O[n]]
    last = alpha[-1]
    m    = np.max(last)
    logP = m + np.log(np.sum(np.exp(last - m)))
    return alpha, logP

# --- 4) Viterbi (log-domain) ---
def viterbi(O, A, C, B):
    N, I     = len(O), A.shape[0]
    delta    = np.zeros((N, I))
    psi      = np.zeros((N, I), int)
    delta[0] = np.log(C + 1e-12) + np.log(B[:, O[0]] + 1e-12)
    for n in range(1, N):
        for j in range(I):
            seq        = delta[n-1] + np.log(A[:, j] + 1e-12)
            psi[n, j]  = np.argmax(seq)
            delta[n, j]= seq[psi[n, j]] + np.log(B[j, O[n]] + 1e-12)
    S_hat = np.zeros(N, int)
    S_hat[-1] = np.argmax(delta[-1])
    for n in range(N-2, -1, -1):
        S_hat[n] = psi[n+1, S_hat[n+1]]
    return S_hat, np.max(delta[-1])

# --- 5) Benchmark + Progress + Profiling ---
def benchmark_with_progress(N, report_every=100_000):
    print(f"\n[1] Generating sequence of length {N} …", flush=True)
    O, _ = generate_sequence_hmm(N, A, C, B)
    print("[2] Starting forward_log …", flush=True)
    for idx in range(0, N, report_every):
        print(f"    forward at step {idx}/{N}", flush=True)
    _, logp_O = forward_log(O, logA, logC, logB)
    print(f"[2] forward_log done, logP = {logp_O:.2f}", flush=True)

    print("[3] Starting viterbi …", flush=True)
    _, logp_S = viterbi(O, A, C, B)
    print(f"[3] viterbi done, logP = {logp_S:.2f}", flush=True)

def main():
    np.random.seed(42)
    N = 1000_000
    pr = cProfile.Profile()
    pr.enable()

    benchmark_with_progress(N)

    pr.disable()
    s = io.StringIO()
    ps = pstats.Stats(pr, stream=s).sort_stats('cumtime')
    ps.print_stats(10)
    print("\n=== Profile Top 10 ===\n" + s.getvalue())

if __name__ == "__main__":
    main()
