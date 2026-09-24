# Push-Relabel Maximum Flow Algorithm

## Project Overview
This project provides an Ada implementation of the **Push-Relabel algorithm** for calculating the maximum flow in a flow network. Unlike path-finding algorithms (like Edmonds-Karp), Push-Relabel operates locally on nodes using a "preflow," pushing excess flow across edges based on a height gradient. 

## Features
- Strong data typing (`Node_Id`, `Capacity_Type`, `Flow_Type`) preventing logic errors.
- **Generic Push-Relabel**: Basic algorithmic implementation selecting active nodes arbitrarily ($O(V^2 E)$).
- **FIFO Push-Relabel**: Utilizes a circular queue to process active nodes fairly, preventing starvation ($O(V^3)$).
- **Highest-Label Push-Relabel**: Heuristic-based approach selecting the active node with the maximum height to optimize discharges ($O(V^2 \sqrt{E})$).

## Testing
To ensure reliability and correctness per V&V (Verification & Validation) standards, the test suite operates under a strict pessimistic assumption: **It assumes the code is fundamentally broken**. Tests `PASS` only when this assumption is explicitly proven false.

### Test Categories
1. **Functional Correctness (Generic, FIFO, Highest-Label)**: Asserts that each specific variant accurately handles baseline capacities, converges complex branching networks (Diamond configurations), and resolves disconnected sinks. *Why it matters: Proves mathematical compliance with the algorithmic specifications.*
2. **Back-flow Verification**: Validates that excess preflow correctly routes back to the Source when restricted by downstream bottlenecks. *Why it matters: The primary mechanism of Push-Relabel involves safely rejecting excess flows via height relabeling.*
3. **Error Handling & Edge Cases**: Deliberately injects malformed bounds, bounds overlaps (Source=Sink), and size-zero arrays. *Why it matters: Validates memory safety and robustness in critical system definitions, ensuring runtime safety in ADA limits.*

## Usage
### Compilation
The project supports the standard Ada GNAT toolchain. Ensure you have `gnatmake` or `gprbuild` installed.
```bash
make all
