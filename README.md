# PRBS7 Verilog-AMS Suite

This project provides a complete environment for generating and verifying PRBS7 sequences in an analog/mixed-signal simulator.

## Files
- **prbs7_gen.vams**: Fibonacci LFSR generator ($x^7 + x^6 + 1$).
- **prbs7_check8b.vams**: High-speed parallel checker (8 bits/cycle).
- **prbs7_tb.vams**: Testbench with Clock, SIPO, and Error Injection.

## Technical Details
- **Logic Threshold**: 0.5V.
- **Timing**: Outputs use `transition` filters (50ps-80ps) for simulator stability.
- **Polynomial**: PRBS7 Standard ($2^7 - 1$ length).

## Instructions
1. Load all `.vams` files into your simulator (Spectre, PrimeSim, etc.).
2. Run a transient analysis for at least `200ns`.
3. To verify error detection, change the `inject_error` parameter to `1` in the testbench.
