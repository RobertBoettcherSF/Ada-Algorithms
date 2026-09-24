# Lagged Fibonacci Generator in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [lagged Fibonacci generator (LFG / LFib)](https://en.wikipedia.org/wiki/Lagged_Fibonacci_generator)

$$
X_{n} = (X_{n-j} \star X_{n-k}) \bmod m \qquad (0 < j < k)
$$

with binary operation $\star \in \{+,-,\mathrm{xor}\}$. Written in Ada 2022 and verified with SPARK (GNATprove Level 4). Create / Reset accept a length-$k$ seed prefix or a single seed expanded via an LCG fill; each `Next` advances the ring buffer and returns $X_n$.

This is the SPARK Level 4 port of the companion package [Ada-Lagged-Fibonacci-Generator](https://github.com/RobertBoettcherSF/Ada-Lagged-Fibonacci-Generator) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes unbounded modular words via `Unsigned_128`, `Long_Float` unit variates, `Max_Lag = 1024`, and `Invalid_Argument` exceptions; this port trades those for hard bounds (`Max_Lag = 128`, `Max_Modulus = 2^{32}`), contracts, and machine-checkable absence of run-time errors. For the same SPARK classroom style on sibling PRNGs, see [Ada-SPARK-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Linear-Congruential-Generator) and [Ada-SPARK-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-ACORN-Generator) (README only — do not `with` those packages here). Cycle-finding contrast: [Ada-SPARK-Brents-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Brents-Algorithm).

## Features
* **Create / Reset / Next**: Two-tap ring-buffer LFG with fixed `Seed_Array (1 .. Max_Lag)`.
* **Three operations**: `Add`, `Subtract`, `Bitwise_Xor` via `Binary_Op` / `Combine`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, index errors, modular wrap in the classroom modulus range, and non-termination of bounded loops.
* **Bounded State**: Static arrays only; no heap / no `Unbounded_*`.
* **Proveable Modular Arithmetic**: `Add_Mod`, `Sub_Mod`, `Xor_Mod`, and LCG fill stay inside a single `mod 2**64` word for $M \le 2^{32}$.
* **Contract Discipline**: Preconditions replace exceptions; invalid inputs are rejected by `Pre` / `Seeds_In_Range` / `Is_Valid_Lags` rather than raised errors.
* **Common lag pairs** that fit the cap: $(24,55)$, $(38,89)$, $(37,100)$, $(30,127)$.

## Deliberate simplifications vs non-SPARK sibling
* `Max_Lag = 128` (not $1024$) so proof obligations stay tractable; pairs $(83,258)$, $(107,378)$, $(273,607)$ are dropped (document only).
* Modulus capped at `Max_Modulus = 2**32` (still the educational default) so $(M-1)+(M-1)$ and the Numerical Recipes LCG step fit without `Unsigned_128`.
* Fixed `Seed_Array (1 .. Max_Lag)` instead of unconstrained seed arrays; used prefix is `1 .. K`.
* No `Next_Float` / `Long_Float` — integer `Next` only (all of the package stays `SPARK_Mode => On`).
* No exceptions: uninitialised / out-of-range uses are precondition violations.
* `Next` is a procedure `(G, Result)` rather than an `in out` function, matching SPARK-friendly styles in sibling packages (e.g. Ada-SPARK-ACORN-Generator).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 177 assertions pass. Running `make prove` reports `Success: all checks proved (318 checks).`

## Testing
* **Functional correctness**: Hand-computed tiny additive / subtractive / XOR sequences, $j=2,k=5$ and $j=3,k=7$ known terms.
* **Determinism**: Reset replay, identical independent generators, LCG seed fill with odd-word forcing for Add / Subtract.
* **Lag pairs**: $(24,55)$, $(38,89)$, $(37,100)$, $(30,127)$ smoke and reproducibility.
* **Contract discipline**: Validation helpers and valid-path coverage; invalid `Pre` cases are not raised as exceptions.
* **Add_Mod / Sub_Mod / Xor_Mod / Combine**: Wrap identities against `Default_Modulus` and small primes.

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
* **GNATprove Level 4:** `Success: all checks proved (318 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
