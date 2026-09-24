# Dijkstra-Scholten Algorithm in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Dijkstra-Scholten algorithm for detecting termination in distributed systems. It models nodes mathematically tracking active/idle computational states, maintaining a spanning tree dynamically via parent references, and validating global network termination utilizing outgoing message deficit counters.

## Features
* **Dynamic Tree Building:** Nodes automatically build relational parent/child tracking upon receipt of computations.
* **Immediate Acknowledgment Variant:** Resolves cyclic or redundant messages by instantly acknowledging duplicate node pings.
* **Cascading Deficit Pruning:** Sub-trees cleanly prune themselves from memory and cascade signals upward once local deficits resolve to 0.
* **Strong Typing Safety:** Strictly bound bounds-checking, strict integer tracking (`Natural`), and custom exceptions (`Invalid_State_Error`, `Negative_Deficit_Error`).

## Testing
This test suite operates on pessimistic Verification and Validation (V&V) methodologies—operating under the rigorous assumption that the code is strictly non-functional/broken until definitively disproved. 

### What Each Category Verifies
* **Functional Correctness:** Assures that mathematical tree properties (deficit increasing on Send, shrinking on Ack) track accurately as active topology shifts. (Tests 1–6).
* **Edge Cases:** Analyzes topological elasticity, such as nodes leaving the tree and instantly re-joining, or Initiators messaging themselves. (Tests 12–13).
* **Global Termination (Validation):** Proves that false termination is structurally impossible, protecting against early closures by validating cascaded node state. (Tests 7–8).
* **Error Handling (Safety):** Purposely subjects the environment to illegal bounds, negative logic underflows, and invalid network behaviors to ensure system trapping. (Tests 9–11).

### Why These Tests Matter
In critical system software or distributed computing, "silent failures" are disastrous. A network misreporting termination could shut off concurrent workers early, leading to fatal data loss. Tests in this suite mathematically verify safety per V&V standards—guaranteeing structural correctness despite our harsh failure assumptions. 

## Usage

### Compilation
The project supports direct Make instructions using standard GNAT compilation architectures. To compile the code:
```bash
make all
