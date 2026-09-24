# Regret (Decision Theory) in Ada

## Project Overview
This software provides an Ada implementation of the **Regret algorithm** from decision theory (often called *Minimax Regret* or *Minimax Deviation*). It models decision-making under uncertainty where an agent attempts to minimize the maximum opportunity loss (regret) caused by making a sub-optimal choice relative to the true state of nature. 

## Features
- **Payoff Matrix Support:** Calculates opportunity loss by subtracting actual payoffs from the maximum possible payoff per state.
- **Cost Matrix Support:** Calculates opportunity loss by subtracting the minimum possible cost from actual costs per state.
- **Minimax Regret Decision Maker:** Evaluates a Regret matrix to find the specific action that guarantees the smallest possible maximum regret.
- **Dynamic Unconstrained Matrices:** Fully supports any valid Ada array boundaries, preventing arbitrary 1-based indexing limits.

## Testing
This codebase adopts a strict Verification and Validation (V&V) methodology, assuming the codebase is broken until mathematically proven otherwise. Tests only output `PASS` when they successfully disprove a failure assumption.

### Verification (Did we build the system right?)
- **Functional Correctness:** Ensures max payoffs/min costs are accurately located, and matrix subtraction logic holds over floating-point calculations (Tests 1, 2).
- **Error Handling:** Validates strict enforcement of edge cases via `Empty_Matrix_Error` when 0-length arrays are passed, ensuring critical system crash prevention (Test 8).
- **Edge Cases & Logic Robustness:** Ensures arrays of size `1x1`, `1xN`, and `Nx1` resolve gracefully (Tests 5, 6, 7). Dynamic bounds shifting ensures pointer offsets are securely managed (Test 12).
- **Tie-Breaking:** Evaluates deterministic outcome selection when multiple actions generate identical risks (Test 9).

### Validation (Did we build the right system?)
- Proves the algorithm genuinely models risk-averse behavior.
- Core invariants are tested: The optimal choice in hindsight *must* yield `0.0` regret (Test 13). Minimax values can mathematically never be negative (Test 14).
- Testing negative numbers checks if real-world debt scenarios translate safely (Test 10). 

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. From the root directory:
```bash
make
