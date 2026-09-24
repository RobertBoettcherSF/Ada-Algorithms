# ACORN Generator in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [ACORN (Additive Congruential Random Number) generator](https://en.wikipedia.org/wiki/ACORN_(PRNG)) of order $k$. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), each step performs an additive sweep

$$
Y_i \leftarrow (Y_i + Y_{i-1}) \bmod M \qquad (i = 1,\ldots,k)
$$

and returns $Y_k$, while $Y_0$ is held fixed. Create / Reset accept a length-$(k+1)$ seed prefix or a single seed expanded via an LCG fill.

This is the SPARK Level 4 port of the companion package [Ada-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-ACORN-Generator) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes unbounded modular words via `Unsigned_128`, `Long_Float` unit variates, and `Invalid_Argument` exceptions; this port trades those for hard bounds (`Max_Order = 64`, `Max_Modulus = 2^{32}`), contracts, and machine-checkable absence of run-time errors. For cycle-finding contrast in the same SPARK classroom style, see the siblings [Ada-SPARK-Floyds-Cycle-Finding-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Floyds-Cycle-Finding-Algorithm) and [Ada-SPARK-Brents-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Brents-Algorithm) (README only — do not `with` those packages here).

## Features
* **Create / Reset / Next**: Order-$k$ additive sweep with fixed `State_Array (0 .. Max_Order)`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, index errors, modular wrap in the classroom modulus range, and non-termination of bounded loops.
* **Bounded State**: Static arrays only; no heap / no `Unbounded_*`.
* **Proveable Modular Arithmetic**: `Add_Mod` and LCG fill stay inside a single `mod 2**64` word for $M \le 2^{32}$.
* **Contract Discipline**: Preconditions replace exceptions; invalid inputs are rejected by `Pre` / `Seeds_In_Range` rather than raised errors.

## Deliberate simplifications vs non-SPARK sibling
* Modulus capped at `Max_Modulus = 2**32` (still the educational default) so $(M-1)+(M-1)$ and the Numerical Recipes LCG step fit without `Unsigned_128`.
* Fixed `State_Array (0 .. Max_Order)` instead of unconstrained seed arrays; used prefix is `0 .. Order`.
* No `Next_Float` / `Long_Float` — integer `Next` only (all of the package stays `SPARK_Mode => On`).
* No exceptions: uninitialised / out-of-range uses are precondition violations.
* `Next` is a procedure `(G, Result)` rather than an `in out` function, matching SPARK-friendly styles in sibling packages.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 233 assertions pass. Running `make prove` reports `Success: all checks proved (231 checks).`

## Testing
* **Functional correctness**: Hand-computed order-1 / order-2 / order-3 sequences, binomial-like sweeps, power-of-two moduli.
* **Determinism**: Reset replay, identical independent generators, LCG seed fill with odd-$Y_0$ forcing when $M$ is even.
* **Contract discipline**: Validation helpers and valid-path coverage; invalid `Pre` cases are not raised as exceptions.
* **Add_Mod**: Wrap identities against `Default_Modulus` and small primes.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Depends`.
* Loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (231 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
