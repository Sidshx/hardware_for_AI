## Asked ChatGPT to identity “computational bottlenecks” in the FrozenLake code from
```https://github.com/ronanmmurphy/Q-Learning-Algorithm```

And the output it gave me was:

## Performance Bottlenecks & Fixes

| Issue                       | Suggested Fix                      |
|-----------------------------|------------------------------------|
| `dict.copy()` every episode| Only update changed entries        |
| Redundant action loops      | Use `max()` or `np.argmax()`       |
| Repeated object creation    | Reuse `State` object               |
| Excessive printing          | Limit output or use logging        |
| Manual Q-table structure    | Use NumPy arrays                   |


## Q. Do the suggestions make sense? How well is it able to identity bottlenecks?

Some suggestions make sense, but I don’t think all will speed things up much. It did pinpoint where to optimize and offered good solutions, though.
## Q. Propose a HW implementation of the biggest bottleneck.
```

+---------------------------------------------------+
|                 Q-Table Memory Bank               |
|   (Dual-port SRAM: [BOARD_ROWS][BOARD_COLS][4])   |
+---------------------------------------------------+
             |                          ^
    read port |                          | write port
             v                          |
+----------------------+     +-------------------------+
|  Max-Value Unit      |     |  Q-Update Unit          |
|  • Parallel fetch    |     |  • αβ accumulator       |
|  • Comparator tree   |     |  • Multiply-accumulate  |
+----------------------+     +-------------------------+
             |                          |
             v                          v
       Action Selector           Direct Memory Write
```

### In-Place Q-Table Updater (HW)

- **SRAM Q-Table**: Dual-port 3D array \[rows\]\[cols\]\[actions\]
- **Max-Value Unit**: Parallel fetch + comparator tree → Q_max in 1 cycle
- **Q-Update Unit**: FMAC computes  
  `Q_new = (1–α)*Q_curr + α*(R + γ*Q_max)`
- **Direct Write**: Write Q_new back to SRAM cell → no full-table copy

## Q. Generate System Verilog code for the HW implementation
gpt.sv
