# Chandra-Toueg Consensus Algorithm Implementation (Ada)

## Project Overview
This repository contains a robust, highly-typed implementation of the **Chandra-Toueg Consensus Algorithm**, written in Ada. The algorithm is foundational in distributed systems, solving consensus in a message-passing environment with crash failures, utilizing an Unreliable Failure Detector (specifically $\lozenge W$ - eventually weak). 

## Features
- **Strict ADA Typing:** Implements distinct custom types (`Value_Type`, `Round_Number`, `Consensus_State`) to ensure system transitions strictly adhere to mathematical constraints.
- **Phase-by-Phase Simulation:** Breaks down the mathematical models strictly into Phase 1 (Estimates), Phase 2 (Proposals), Phase 3 (Voting/Failure Detection), and Phase 4 (Decision).
- **Rotating Coordinator Variant:** Evaluates coordinator election via modular arithmetic across advancing rounds.
- **Unreliable Failure Detection ($\lozenge W$) Simulation:** Integrates mechanisms for processes to simulate suspicion of coordinators (`Suspect()` routine) resulting in deterministic `NACK` generation instead of relying purely on network timeouts.
- **Crash Simulation:** Injects complete and permanent halts to individual nodes (`Crash_Process()`) to evaluate Byzantine-like network safety faults.

## Testing (Verification and Validation)
Our approach follows stringent V&V methodologies applied to critical systems, operating under the pessimistic assumption that network-oriented code is inherently broken until deterministically proven otherwise.

### What The Categories Verify
1. **Functional Correctness (Tests 1, 2, 3, 4, 6, 8, 10):** Validates the mathematical precision of the code against the Wikipedia specification. It ensures rotating coordinators are correctly calculated, phase message exchanges happen exactly as drafted, and properties like *Agreement* and *Integrity* hold. 
2. **Error Handling & Suspicion (Tests 7, 9):** Validates the Unreliable Failure Detector mechanism. Suspected coordinators successfully force algorithm advancement to next rounds without system halts.
3. **Edge Cases (Test 5, 13):** Validates system behavior when parameters ride boundary margins, such as lacking majority input, or multi-round success pipelines.
4. **Safety & Robustness (Tests 11, 12):** Enforces critical network properties: ensures *Termination* occurs with $F < N/2$ failures, and critically, verifies the system halts safely rather than reaching a fractured state when $F \ge N/2$ crashes occur.

### Why These Tests Matter
In critical distributed systems, non-deterministic failures are catastrophic. These deterministic tests inject exact system failures to isolate variables, ensuring reliability, safety, and strict consensus behavior under adverse conditions. The test framework ensures that, despite assuming the code may fail on edge cases, mathematical constraints are rigidly upheld.

## Usage

### Compilation
The codebase resides entirely in the root directory and can be compiled natively using `make` or standard GNAT tools.

```bash
# Build executables
make all

# Alternative direct GNAT command:
gnatmake -P chandra_toueg.gpr
