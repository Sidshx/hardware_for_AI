import numpy as np
import cProfile, pstats
from hmm_demo_profiling_progress import generate_sequence_hmm, forward_log, viterbi, A, C, B, logA, logC, logB

def run_forward_viterbi(N):
    # generate once
    O, _ = generate_sequence_hmm(N, A, C, B)

    # forward
    _, logp_O = forward_log(O, logA, logC, logB)
    # viterbi
    _, logp_S = viterbi(O, A, C, B)

if __name__ == "__main__":
    N = 200_000
    profiler = cProfile.Profile()
    profiler.enable()

    run_forward_viterbi(N)

    profiler.disable()
    profiler.dump_stats("fv.prof")
    print(f"Profile dumped to fv.prof for N={N}")
