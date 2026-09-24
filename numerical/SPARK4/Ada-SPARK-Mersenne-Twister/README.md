# Mersenne Twister in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [Mersenne Twister](https://en.wikipedia.org/wiki/Mersenne_Twister) MT19937 (32-bit) generator of Matsumoto and Nishimura. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), the generator keeps a state vector of $N = 624$ words of `Unsigned_32`, applies the classical Twist recurrence with matrix $A$, then Tempers before each extract. The period is

$$
2^{19937}-1
$$

Create / Init / Reset seed a generator; each `Next` advances the index (Twisting when the buffer is exhausted) and returns a tempered 32-bit word.

This is the SPARK Level 4 port of the companion package [Ada-Mersenne-Twister](https://github.com/RobertBoettcherSF/Ada-Mersenne-Twister) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling also exposes MT19937-64 and auto-seeds uninitialised state with $5489$; this port keeps a single proveable 32-bit engine, replaces auto-seed with `Is_Initialised` preconditions, and uses `Next (G, Result)` procedures. For the same SPARK classroom style on sibling PRNGs, see [Ada-SPARK-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Linear-Congruential-Generator), [Ada-SPARK-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-ACORN-Generator), [Ada-SPARK-Blum-Blum-Shub](https://github.com/RobertBoettcherSF/Ada-SPARK-Blum-Blum-Shub), and [Ada-SPARK-Lagged-Fibonacci-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Lagged-Fibonacci-Generator) (README only — do not `with` those packages here).

## Features
* **Create / Init / Reset / Next**: Classical MT19937 with fixed `MT_Array (0 .. N−1)` and `Index` in $0 .. N$ ($N$ means “need Twist”).
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, index errors, and non-termination of bounded loops.
* **Bounded State**: Static array of $624$ words; no heap / no `Unbounded_*`.
* **Three-loop Twist**: Matches the reference `mt19937ar.c` split ($0 .. N-M-1$, $N-M .. N-2$, wrap) so every index is a static offset — no $I \bmod N$ in the hot path.
* **Contract Discipline**: Preconditions replace exceptions; uninitialised use is a `Pre` violation rather than auto-seed.
* **Known-answer tests**: First outputs for seed $5489$ match OEIS A221557 / C++ `std::mt19937`.

## Deliberate simplifications vs non-SPARK sibling
* **MT19937 32-bit only** — MT19937-64 ($N=312$ of `Unsigned_64`) is omitted so Level 4 proofs stay tractable; the 32-bit engine already carries a $624$-iteration Twist.
* No auto-initialisation on first `Next`: callers must `Create` / `Init` (contracts enforce `Is_Initialised`).
* No exceptions: uninitialised / out-of-range uses are precondition violations.
* `Next` is a procedure `(G, Result)` rather than an `in out` function, matching SPARK-friendly styles in sibling packages (e.g. Ada-SPARK-ACORN-Generator).
* All of the package stays `SPARK_Mode => On`.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 36 assertions pass. Running `make prove` reports `Success: all checks proved (102 checks).`

## Testing
* **Known-answer**: Seed $5489$ first $20$ outputs vs OEIS A221557 / `std::mt19937`.
* **Functional correctness**: Reproducibility, seed independence, zero-seed fill, Temper vs `Next`.
* **Determinism**: `Reset` replay, identical independent generators, state isolation.
* **Boundary**: Exhaust $N=624$ words to force Twist; Index progression $N \to 1 \to \cdots \to N$.
* **Contract discipline**: Create / Init / Reset postconditions; invalid `Pre` cases are not raised as exceptions.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Depends`.
* Init fill and Twist use bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (102 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
