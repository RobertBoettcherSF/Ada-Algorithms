# Brent's Cycle-Finding Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Brent's cycle-finding algorithm](https://en.wikipedia.org/wiki/Cycle_detection#Brent's_algorithm) for [cycle detection](https://en.wikipedia.org/wiki/Cycle_detection) in the orbit of an endofunction on a finite set. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it recovers the cycle length $\lambda$ first via powers-of-two teleports, then the tail length $\mu$, of a $\rho$-shaped trajectory without allocating heap storage.

Classroom model: a successor array `Next(1 .. N)` with images in $0 .. N$, where $0$ is `Null_Index` (no successor). A total functional graph always cycles; a path that reaches the sentinel has no cycle.

This is the SPARK Level 4 port of the companion package [Ada-Brents-Algorithm](https://github.com/RobertBoettcherSF/Ada-Brents-Algorithm) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Nodes`, exceptions, and generic callback walkers; this port trades those for hard bounds (`Max_N = 64`), contracts, and machine-checkable absence of run-time errors. For a tortoise-and-hare contrast in the same classroom model, see the sibling [Ada-SPARK-Floyds-Cycle-Finding-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Floyds-Cycle-Finding-Algorithm) (README only — do not `with` that package here).

## Features
* **Detect / Find_Cycle**: Powers-of-two phase recovers $\lambda$ (and a meeting node); full Brent then recovers `Start_Node` and $\mu$.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, index errors, and non-termination of bounded loops.
* **Bounded Maps**: Static arrays only; no heap / no `Unbounded_*`.
* **Naive Reference**: `Find_Cycle_Naive` for teaching contrast ($O(\mu+\lambda)$ space).
* **Graph Builders**: `Pure_Cycle`, `Rho_Graph`, `Path_To_Sink`, `Self_Loop_Chain`, `Two_Cycles`, `Wikipedia_Example`.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 63 assertions pass. Running `make prove` reports `Success: all checks proved (190 checks).`

## Testing
* **Functional correctness**: Pure cycles, $\rho$-graphs, open paths, self-loops, two-component graphs, and the Wikipedia figure.
* **Agreement**: Brent vs naive reference on the same maps.
* **Contract discipline**: Preconditions replace exceptions; invalid maps are rejected by `Is_Valid_Map` rather than raised errors.
* **Detect fills $\lambda$**: Unlike Floyd's phase-1 meeting, Brent's Detect already returns the exact cycle length.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (190 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
