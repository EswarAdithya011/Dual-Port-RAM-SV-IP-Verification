# Dual-Port RAM — SystemVerilog IP Verification

A complete **SystemVerilog** verification environment for a **synchronous Dual-Port RAM** with independent read and write ports. Built from scratch without UVM, using a layered testbench architecture with constrained-random stimulus, functional coverage, SVA assertions, and a self-checking scoreboard.

---

## 📐 Architecture

```
┌────────────────────────────────────────────────────────────┐
│                        Testbench (tb)                      │
│                                                            │
│  ┌──────────┐    ┌─────────────┐    ┌──────────────────┐   │
│  │ Generator │───►│ Write Driver │───►│                  │   │
│  │          │    └─────────────┘    │   Dual-Port RAM   │   │
│  │          │    ┌─────────────┐    │       (DUT)       │   │
│  │          │───►│ Read Driver  │───►│                  │   │
│  └──────────┘    └─────────────┘    └──────────────────┘   │
│                                       │            │       │
│                  ┌──────────────┐     │            │       │
│                  │ Write Monitor│◄────┘            │       │
│                  └──────┬───────┘                  │       │
│                         │         ┌──────────────┐ │       │
│                         │         │ Read Monitor │◄┘       │
│                         │         └──────┬───────┘         │
│                         ▼                ▼                 │
│                  ┌─────────────────────────┐               │
│                  │      Scoreboard         │               │
│                  │  (Reference Model +     │               │
│                  │   Compare Logic)        │               │
│                  └─────────────────────────┘               │
│                                                            │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │ Functional        │    │ SVA Assertions (bind)        │  │
│  │ Coverage          │    │  • Reset check               │  │
│  │  • R/W combos     │    │  • Write-then-read integrity │  │
│  │  • Address ranges │    │  • Read-data stability       │  │
│  │  • Data corners   │    │  • No X/Z on controls        │  │
│  └──────────────────┘    └──────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

---

## 🧩 DUT: Dual-Port RAM

| Feature | Details |
|---|---|
| **Data Width** | 8 bits (configurable) |
| **Address Width** | 8 bits → 256 locations (configurable) |
| **Write Port** | Synchronous, edge-triggered |
| **Read Port** | Synchronous, 1-cycle registered output |
| **Reset** | Asynchronous active-high — clears all memory and `read_data` |

---

## 📁 File Structure

| File | Description |
|---|---|
| `params.sv` | Package with configurable `ADDR_WIDTH` and `DATA_WIDTH` parameters |
| `interface.sv` | SystemVerilog interface with clocking blocks and modports for each agent |
| `design.sv` | RTL design — synchronous dual-port RAM |
| `transaction.sv` | Randomized transaction class with constraints (enable distribution, hazard avoidance, data corners) |
| `generator.sv` | Stimulus generator — creates constrained-random transactions and distributes to drivers |
| `write_driver.sv` | Drives write-port signals to the DUT via clocking block |
| `read_driver.sv` | Drives read-port signals to the DUT via clocking block |
| `write_monitor.sv` | Passively observes write-port activity and forwards to scoreboard |
| `read_monitor.sv` | Passively observes read-port and captures data with correct 1-cycle latency alignment |
| `reference_model.sv` | Shadow memory with write-tracking to enable meaningful read comparisons |
| `scoreboard.sv` | Self-checking comparator — skips unwritten addresses, reports PASS/FAIL/SKIP |
| `coverage.sv` | Functional coverage — R/W combinations, address ranges, data corner cases, cross coverage |
| `assertions.sv` | SVA properties bound to DUT — reset, write-then-read, data stability, no X/Z |
| `environment.sv` | Orchestrates all verification components — pre_test, test, post_test flow |
| `test.sv` | Top-level test program — instantiates environment and sets transaction count |
| `testbench.sv` | Top-level module — clock/reset generation, DUT + test instantiation |
| `header.svh` | Compilation header — includes all source files in dependency order |
| `run.sh` | Xcelium (xrun) simulation script with coverage enabled |
| `dump.tcl` | TCL script for VCD waveform dumping |

---

## ✅ Verification Features

### Constrained-Random Stimulus
- At least one port (read or write) is active per transaction
- Write-enable biased 70/30 to build memory state faster
- Same-address RAW hazard prevention (`read_addr ≠ write_addr` when both enabled)
- Data corner biasing — ensures `0x00` and `0xFF` are exercised within feasible transaction counts

### Self-Checking Scoreboard
- Reference model with shadow memory tracks all DUT writes
- Reads are compared only for previously-written addresses (skips meaningless `0 == 0` comparisons)
- Reports PASS / FAIL / SKIP counts with a summary verdict

### Functional Coverage
- **`cp_write_en` / `cp_read_en`**: Active vs. idle bins for each port
- **`cp_rw_combo`**: Cross of read/write enables — all 4 combinations
- **`cp_write_addr` / `cp_read_addr`**: Address space split into 4 quartile bins
- **`cp_write_data`**: Corner values (`0x00`, `0xFF`) and general range
- **`cp_addr_data_cross`**: Cross of address quartiles × data corners

### SVA Assertions (Bound to DUT)
- **Reset clears `read_data`**: After reset, output must be `8'h00`
- **Write-then-read integrity**: Data written at address A appears on read one cycle later
- **Read-data stability**: Output holds steady when `read_en` is deasserted
- **No X/Z on control signals**: `write_en` and `read_en` must never be unknown

---

## 🚀 Running the Simulation

### Prerequisites
- **Cadence Xcelium** (xrun) — tested with Xcelium 25.03

### Simulate
```bash
xrun -Q -unbuffered \
     -timescale 1ns/1ns \
     -sysv \
     -incdir . \
     -access +rw \
     -coverage functional \
     design.sv testbench.sv
```

Or use the provided script:
```bash
source run.sh
```

### Expected Output
```
========================================
           SCOREBOARD REPORT
========================================
  Total Meaningful Checks     : <N>
  PASS                        : <N>
  FAIL                        : 0
  SKIP (addr never written)   : <N>
========================================
  *** ALL MEANINGFUL TESTS PASSED ***
========================================
========================================
          COVERAGE REPORT
  cg_ram_ops coverage = XX.XX %
========================================
```

---

## ⚙️ Configuration

Edit [`params.sv`](params.sv) to change RAM dimensions:

```systemverilog
package params_pkg;
  parameter ADDR_WIDTH = 8;   // 2^8 = 256 locations
  parameter DATA_WIDTH = 8;   // 8-bit data bus
endpackage
```

Transaction count is set in [`test.sv`](test.sv):

```systemverilog
env.gen.gen_count = 200;   // number of random transactions
```

---

## 📜 License

This project is provided for educational and reference purposes.