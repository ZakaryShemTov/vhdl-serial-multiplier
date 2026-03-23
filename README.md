# VHDL Serial Multiplier

Synchronous serial 4-bit multiplier implemented in VHDL using a 
shift-accumulate algorithm with a CU/OU split architecture.  
Two implementations are provided: Radix-2 (baseline) and Radix-16 
(optimized), demonstrating a 4× reduction in clock cycles.

## Architecture

The system is divided into two entities connected at the top level:

**Control Unit (CU)** — Moore FSM with 5 states:  
`Idle → Load → Check → Add → Shift → Done`  
Generates: `load_sig`, `clear_sig`, `add_sig`, `shift_sig`, `done_sig`

**Operational Unit (OU)** — RTL datapath containing:  
- `RA`: multiplicand register (8-bit)  
- `RB`: multiplier register (4-bit)  
- `P`: accumulator (partial product)  
- Signed operand support via sign extraction and abs_val function  
- `EQZ` feedback to CU when RB is exhausted

## Performance

| Implementation | Clock Cycles (4×4 bit) | Strategy |
|---|---|---|
| Radix-2 | 4 | 1 bit/cycle |
| Radix-16 | 1 | 4 bits/cycle (CHUNK_BITS = 4) |

## Verification

| Implementation | Testbench Coverage | Severity |
|---|---|---|
| Radix-2 | 10 signed pairs (neg×neg, neg×pos, edge cases) | ERROR |
| Radix-16 | All 256 combinations (0–15 × 0–15) | NOTE |

## Repository Structure
```
vhdl-serial-multiplier/
├── radix2/
│   ├── src/
│   │   ├── CU.vhd          # FSM Control Unit
│   │   ├── OU.vhd          # Datapath (Operational Unit)
│   │   └── MulTop.vhd      # Top-level structural entity
│   └── testbench/
│       └── TB.vhd          # 10 signed test cases
├── radix16/
│   ├── src/
│   │   ├── CU.vhd          # FSM with iteration counter
│   │   ├── OU.vhd          # 4-bit chunk datapath
│   │   └── MulTop.vhd      # Top-level structural entity
│   └── testbench/
│       └── TB.vhd          # Self-checking, 256 combinations
└── README.md
```

## Tools

Quartus Prime | ModelSim | VHDL-2008
