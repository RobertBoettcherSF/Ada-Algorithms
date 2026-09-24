# Binary GCD (Stein) in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Stein’s algorithm](https://en.wikipedia.org/wiki/Binary_GCD_algorithm) (binary GCD / binary Euclidean algorithm): compute $\gcd(u,v)$ for nonnegative integers using only arithmetic shifts, comparisons, and subtraction — no division or remainder in the main Stein path.

$$
\begin{align*}
\gcd(u,0) &= u \\
\gcd(2u,2v) &= 2\cdot\gcd(u,v) \\
\gcd(u,2v) &= \gcd(u,v) && \text{($u$ odd)} \\
\gcd(u,v) &= \gcd(u,v-u) && \text{($u,v$ odd, $u\le v$)}
\end{align*}
$$

Written in Ada 2022 and verified with SPARK (GNATprove Level 4). Domain convention: $\gcd(0,0)=0$.

This is the SPARK Level 4 port of the companion package [Ada-Binary-GCD](https://github.com/RobertBoettcherSF/Ada-Binary-GCD) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses the same `Binary_GCD` / `U64` API with `SPARK_Mode => Off` and an identity-driven recursive Stein body; this port turns `SPARK_Mode => On`, adds contracts, bounds the outer Stein reduction for termination, and keeps a local classical Euclidean reference for cross-checks (no sibling `with`). Closest SPARK sibling: [Ada-SPARK-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Euclidean-Algorithm) (classical remainders + a related `Binary_Gcd` helper). Related number-theory siblings: [Ada-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Euclidean-Algorithm), [Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm).

## Features
* **`Gcd`**: Iterative Stein binary gcd (preferred). Strips shared factors of two, keeps an odd $u$, then subtract / re-normalize with a bounded outer loop.
* **`Gcd_Recursive`**: Educational entry with the same contracts on `Max_Educational`; body delegates to iterative Stein for a compact Level 4 VC (identity-driven recursion remains in Ada-Binary-GCD).
* **`Gcd_Euclidean`**: Classical successive-remainder reference on the same `U64` domain (tests cross-check Stein).
* **`Are_Coprime` / bit helpers**: Coprimality; `Trailing_Zeros`, `Shift_Left` / `Shift_Right`, `Is_Odd`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of run-time errors, non-termination of shift / trailing-zero / Stein loops (bounded classroom ceiling with Euclidean fallback).
* **Contract Discipline**: No exceptions; zero-case and positivity posts on gcd; recursive Pre caps operands at `Max_Educational`.

## Deliberate simplifications vs non-SPARK sibling
* `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Loop_Variant` (no exceptions).
* Iterative Stein uses a bounded outer reduction (`Max_Stein_Steps`) so termination is immediate for the prover; falls back to `Gcd_Euclidean` if the classroom ceiling were ever hit (same pattern as `Binary_Gcd` in Ada-SPARK-Euclidean-Algorithm).
* `Gcd_Recursive` keeps the educational Pre / Post API but delegates to iterative `Gcd` so Level 4 discharges a compact VC; the Wikipedia identity-driven recursive body stays in Ada-Binary-GCD.
* Full “greatest” / Divides uniqueness on modular words is not claimed without ghost lemmas — tests check Stein against classical Euclidean.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 167 assertions pass. Running `make prove` reports `Success: all checks proved (77 checks).`

## Testing
* **Bit helpers**: Trailing-zero counts, shifts, oddness.
* **Stein basics**: Classical pairs $(54,24)$, $(270,192)$, powers of two, mixed parity, Fibonacci-ish pairs.
* **Cross-checks**: Commutativity; `Gcd_Recursive` vs `Gcd` on educational sizes; Stein vs `Gcd_Euclidean` including a $0..40$ grid and large $2^{63}$ edges.
* **Coprimality**: Primes, zeros, and mixed pairs.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global`.
* Trailing-zero / shared-factor / odd-strip loops use `pragma Loop_Variant`; outer Stein reduction is a bounded `for` loop.
* **GNATprove Level 4:** `Success: all checks proved (77 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
