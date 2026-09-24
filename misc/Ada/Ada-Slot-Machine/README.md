Project Overview: 
This Ada 2023 project implements the core algorithms driving both classic mechanical and modern video slot machines. It models the crucial translation layers of a slot engine: virtual-to-physical reel mapping for deterministic but weighted stops, wrap-around symbol window extraction, matrix generation for simulated spins, multi-line payout evaluation, and mathematical mechanisms for analyzing Return to Player (RTP) and hit probabilities.

Features:
* Virtual Reel Mapping: Converts expansive RNG boundaries into precise physical stops to allow weighted probability and "near misses".
* Multi-Reel Grid Generation: Constructs arbitrary N-by-M visible symbol grids, correctly wrapping physical reels.
* Classic & Wild Payline Evaluators: Scores horizontal/diagonal vectors detecting exact matches or complex wildcard substitutions.
* Scatter Evaluator: Computes volume-based payouts unaffected by active paylines.
* Theoretical Hold & RTP Calculation: Helper functions evaluate combinatorial hit odds and Expected Value (EV) per wager.
* Strict Type Contracts: Strongly typed domain models, utilizing Ada 2023 pre/postconditions for mathematical integrity.

Usage: 
Compile the project and run the standalone test suite by simply executing `make test` in the terminal. The output will print detailed checks for every integrated subsystem demonstrating successful algorithm processing.

Testing: 
The standalone `tests.adb` validates 13 distinct behaviors using 39 assertions. It heavily tests expected logic paths (payout math, hit rates), boundary configurations (reel strip wrapping, edge RNG mapping), and defensive safety constraints (raising precondition assertions when providing misaligned array bounds or out-of-bounds configurations), verifying overall stability under ISO/IEC 8652:2023 standards.

Building: 
Requires a standard GNAT compiler supporting Ada 2023 (-gnat2022). Type `make` to invoke the GNAT build toolchain utilizing the provided `slot_machine.gpr` project file.
