# ECE510 Hardware for AI/ML — Siddesh Patil Portfolio

This repository documents my complete work for ECE510 (Hardware for AI/ML, Spring 2025). It includes weekly challenges, profiling, hardware design, verification, and ASIC flow for my final Viterbi accelerator project.

---

## 📂 Repository Structure

```bash
.
├── Project/
│   ├── Verilog_Code/           # All synthesizable RTL: viterbi_pe, viterbi_top, tb
│   ├── Python_Profiling/       # Python profiling, bottlenecks, forward/viterbi analysis
│   ├── Cocotb/                 # Cocotb-based verification and test automation
│   ├── OpenLane/               # ASIC synthesis (Sky130A) configs, flow runs
│   └── Tests/                  # Systolic array test scripts
│
├── Challenges/                 # All weekly challenges (C1 - C18)
│
├── Project_Report.pdf          # Final summarized project report
├── README.md                   # This file
```
# Viterbi Accelerator Project

## 🔧 Project Summary

Design a hardware accelerator for the Viterbi and Forward algorithms (Hidden Markov Model), fully verified in simulation and partially synthesized using OpenLane 2 on Sky130A open-source PDK.

## 📌 Goal

- Design and verify a hardware accelerator for the Viterbi and Forward algorithms.
- Utilize OpenLane 2 and Sky130A open-source PDK for synthesis.

## 📌 Motivation

Viterbi decoders are widely used in:

- Speech recognition
- DNA sequence alignment
- Error correction (5G / wireless)
- Hidden-state estimation problems

Its **add-compare-select (ACS)** structure maps naturally to systolic arrays, making it well-suited for hardware acceleration.

# ECE510: HMM Hardware Acceleration

🚀 **Project Development Flow**

---

## 1️⃣ Software Profiling

**Initial implementation:** `hmm_demo_profiling_progress.py`

- **Tools Used:** Python `cProfile` and `py-spy` for identifying bottlenecks.
- **Input size:** N = 1,000,000

| Function      | Total Time | Loop Time | NumPy Ops |
| ------------- | ---------- | --------- | --------- |
| `forward_log()` | 38 sec | 15 sec | 23 sec |
| `viterbi()`   | 20 sec | 13.8 sec | 6.2 sec |
| Sequence Gen  | ~10 sec | - | - |

**Conclusion:**  
`viterbi()` ACS loop selected for hardware acceleration.

---

## 2️⃣ RTL Design

- ✅ `viterbi_pe.v` — Parameterized Processing Element (max-plus)
- ✅ `viterbi_top.v` — Top-level FSM with states: INIT, FORWARD, BACKTRACK, DONE
- ✅ Arrays flattened from 2D → 1D for synthesis compatibility.
- ✅ Register pipelining inserted for synthesis timing.

**Key Fix:**  
FSM refactored from 5 states → 4 states to eliminate deadlock on `obs_ready` signal.

---

## 3️⃣ Verification Flow

- ✅ Icarus Verilog simulations (`sim_viterbi.vvp`)
- ✅ SystemVerilog Testbench (`tb_viterbi.v`)
- ✅ Cocotb Python-based testbench (`test_viterbi_cocotb.py`)
  - Fully automated functional verification
  - Python reference model cross-checked

---

## 4️⃣ ASIC Flow — OpenLane 2

- ✅ Synthesized design using Yosys + OpenLane 2 on Sky130A PDK.
- ✅ Design target: 100 MHz
- ✅ Flattened signals for place & route.

**Config files:**

- `config.json`
- `constraints.sdc`
- `pin_order.cfg`

**Note:**  
Final P&R run encountered some congestion, expected due to flattened 1D buses without hierarchical placement.

---

⚠ **Known Issues and Iterations**

- ✅ Arrays flattened due to OpenLane synthesis issues.
- ✅ FSM deadlock resolved with handshake removal.
- ✅ OpenLane DRC violations still remain (antenna + congestion).
- ✅ Multiple design iterations (~6+) to fully synthesize and verify.

---
# ECE510: Hw_for_AI - HMM Hardware Acceleration

## 📊 Viterbi Accelerator Benchmark Summary

| Stage          | Tool             | Result  |
|----------------|------------------|---------|
| Functional Sim | Icarus + Cocotb  | ✅       |
| Python Profiling | cProfile      | ✅       |
| ASIC Synthesis | OpenLane 2       | ✅       |
| P&R            | OpenLane 2       | Partial |
| Target Freq    | Sky130A          | 100 MHz |

---

## 🧪 Challenges Completed

This repository documents the full submission for 18 course challenges:

| Challenge | Topic                    | Summary                                       |
|-----------|---------------------------|-----------------------------------------------|
| 1         | Beyond CMOS Devices       | Reviewed IRDS beyond CMOS roadmap             |
| 2         | Intrinsic Computation     | Studied physical non-instruction computation  |
| 3         | Differential Equation Solvers | Investigated analog op-amp approaches    |
| 5         | Instruction Profiling     | Bytecode analysis, disassembly, and cProfile |
| 6         | Perceptron (NAND/XOR) Training | Perceptron training using sigmoid activation |
| 7         | Perceptron Visualization  | 2D plane separation, animated plots          |
| 9         | Bootstrapping HW Accelerator | Heilmeier questions, architecture analysis |
| 10        | FrozenLake Bottleneck Analysis | Identified Q-value update as HW candidate |
| 12        | HW/SW Partitioning        | Decided to accelerate ACS block              |
| 13        | CUDA SAXPY Profiling      | Benchmarked GPU scaling (NVIDIA Tesla K80)   |
| 14        | CUDA Fibonacci            | Parallelized Fibonacci sequence generation   |
| 15        | First HDL Design Flow     | Wrote synthesizable SystemVerilog for Viterbi |
| 18        | OpenLane Physical Design  | Ran OpenLane 2 ASIC flow on Sky130A          |
| Others    | Multiple                  | Full documentation attached in Challenges folder |

---

## 💻 Key Tools Used

- ✅ Python 3.10 (`NumPy`, `cProfile`, `matplotlib`, `py-spy`)
- ✅ Verilog/SystemVerilog
- ✅ Icarus Verilog (`iverilog`, `vvp`)
- ✅ Cocotb (with `pytest` automation)
- ✅ OpenLane 2 (Sky130A PDK)
- ✅ Google Colab (for CUDA profiling)
- ✅ NVIDIA CUDA (for SAXPY/Fibonacci)

---

*Full documentation is included in the `Challenges` folder.*
# ECE510: Hw_for_AI - HMM Hardware Acceleration

## How to Run

### Verilog Simulation

```bash
cd Project/verilog_code/
iverilog -g2012 -o sim_viterbi.vvp viterbi_pe.v viterbi_top.v tb_viterbi.v
vvp sim_viterbi.vvp
```

### Cocotb Verification

```bash
cd Project/cocotb/
make SIM=icarus
python test_viterbi_runner.py 
```

### Python Profiling

```bash
cd Project
python3 hmm_demo_profiling_progress.py
```

### OpenLane 2 Flow

```bash
cd Project/openlane/Siddesh
sudo openlane --dockerized ./config.json
```

## 📄 Full Report

- See `Project_Report.pdf` for full technical details.
- All challenges are documented weekly under the `Challenges/` directory.

## ✅ Self-Assessment Statement

This repository represents a complete submission for **ECE510 Spring 2025**, documenting my full design cycle from profiling, RTL design, verification, hardware synthesis, and self-directed debugging iterations.

## ✨ Acknowledgement

Special thanks to **ChatGPT** (LLM prompts included throughout the repo), **Prof. Christof Teuscher**, and the entire **ECE510 community** for an incredible hands-on hardware design experience.
