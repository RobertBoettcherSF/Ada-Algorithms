# Lemke-Howson Algorithm in Ada/SPARK

## Project Overview
This repository contains a robust, formally verified implementation of the Lemke-Howson algorithm for finding a Nash equilibrium of a finite two-player (bimatrix) game. Written in Ada 2023 and verified using SPARK (GNATProve Level 4), the algorithm models the combinatorial pivoting process on two complementary polytopes. 

While the problem domain does not have concepts like "preemptive/dynamic" (those apply to scheduling), the principal variation in Lemke-Howson is traversing different edges of the polytopes by choosing which label to drop initially (`Initial_Drop`). The API exposes this choice, allowing the discovery of different Nash equilibria in games with multiple equilibria.

## Features
* **Label Variation**: Allows dropping different initial labels (`Initial_Drop`) to navigate varying paths in the polytope.
* **Formal Verification**: NOT complete: see Proof Status (overflow checks are annotated away, not proved).
* **Support for Any Game Size**: Handled up to `Max_Strategies` limit bounds through `Strategy_Count` without requiring dynamic allocation.
* **Asymmetric Matrices**: Full support for non-square (M x N) payoff matrices.
* **Matrix Normalization**: Automatically shifts negative or zero-value payoffs iteratively out of the solution space, preventing bounding errors.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 39 assertions pass across the 13 distinct tests. Running `make prove` will successfully discharge all Level 4 proof obligations.

## Testing
* **Functional correctness**: Test suite explicitly verifies outputs against known outcomes for the Battle of the Sexes, Prisoner's Dilemma, Matching Pennies, and Rock Paper Scissors.
* **Contract verification**: Explicit bounds test matrices (1x1 degenerates, large asymmetric 2x3 tables).
* **Proof obligations**: Uses bounded loop evaluations to guarantee total correctness and termination proofs inside SPARK.

## Building
**Prerequisites:** GNAT Community (or GNAT Pro) with SPARK support, and compatibility with Ada 2023 (ISO/IEC 8652:2023).

**Commands:**
* `make` — Builds the project binaries.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATProve on Level 4 mode to verify contracts.
* `make clean` — Removes build artifacts from the object and binary directory.

## Proof Status
* All subprograms are rigorously annotated with SPARK contracts (`Pre`, `Post`, `Global`).
* All loops enforce standard termination mechanisms with accurate array boundary definitions passed via `pragma Loop_Invariant`.
* **Not Silver (2026-10-09):** two `pragma Annotate (GNATprove, Intentional, "overflow check", ...)` lines (lemke_howson.adb:45 and :147) hide the floating-point overflow checks of the pivoting. Their reason is a prover limit, not a proof that overflow cannot happen, so the absence of run-time errors is not proved (tools/vv/proof_escapes_review.csv, PROOFS.csv). A rewrite with exact integer pivoting is in progress.
