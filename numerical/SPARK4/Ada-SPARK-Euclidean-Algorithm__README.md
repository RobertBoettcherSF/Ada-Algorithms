# Euclidean Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classical [Euclidean algorithm](https://en.wikipedia.org/wiki/Euclidean_algorithm) for the greatest common divisor

$$
\gcd(a,0) = a, \qquad \gcd(a,b) = \gcd(b,\, a \bmod b) \quad (b \neq 0)
$$

Written in Ada 2022 and verified with SPARK (GNATprove Level 4). The package also offers LCM on a capped educational domain, coprimality, remainder-step counts, and Stein’s binary GCD (same results as classical `Gcd`).

This is the SPARK Level 4 port of the companion package [Ada-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Euclidean-Algorithm) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses the shorter package name `Euclidean`, signed `Long_Integer` operands with `Abs_LI`, and `Invalid_Argument` for oversized LCM; this port trades those for an unsigned `Value` (`mod 2**64`), contracts, and machine-checkable absence of run-time errors. For the same SPARK classroom style, see [Ada-SPARK-Blum-Blum-Shub](https://github.com/RobertBoettcherSF/Ada-SPARK-Blum-Blum-Shub) (Gcd helpers), [Ada-SPARK-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Linear-Congruential-Generator), and [Ada-SPARK-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-ACORN-Generator) (README only — do not `with` those packages here). Related number-theory siblings: [Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm), [Ada-Binary-GCD](https://github.com/RobertBoettcherSF/Ada-Binary-GCD).

Note: a spreadsheet row title may say “Euclidian”; Wikipedia spelling is **Euclidean**.

## Features
* **`Gcd` / `Gcd_Recursive`**: Classical Euclidean gcd by successive remainders (iterative preferred for SPARK; recursive with `Subprogram_Variant`). $\gcd(0,0)=0$.
* **`Lcm`**: Least common multiple on `Max_Educational` with overflow-safe Pre (no exceptions).
* **`Are_Coprime` / `Division_Steps` / `Binary_Gcd`**: Coprimality, remainder-iteration counts, and Stein’s binary gcd.
* **`Divides`**: Expression-function helper for contracts and classroom checks.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of modular wrap in the LCM classroom bound, division-by-zero, and non-termination of remainder / shift loops.
* **Contract Discipline**: Preconditions replace exceptions; oversized LCM is a `Pre` violation rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* Unsigned `Value is mod 2**64` replaces signed `Long_Integer` / `Abs_LI` (nonnegative by construction).
* No exceptions: LCM domain guard is `Pre => A <= Max_Educational and B <= Max_Educational`.
* Package name `Euclidean_Algorithm` (files `euclidean_algorithm.*`) for SPARK-series consistency; non-SPARK sibling keeps the shorter `Euclidean` name.
* `Gcd` / `Gcd_Recursive` posts cover zero-cases and positivity; `Divides` is provided as a helper and checked in tests. Full “greatest” / Divides closure on modular words is not claimed without ghost lemmas.
* `Binary_Gcd` uses a bounded outer reduction loop so termination is immediate for the prover (fallback to classical `Gcd` if the classroom ceiling were ever hit).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 1304 assertions pass. Running `make prove` reports `Success: all checks proved (70 checks).`

## Testing
* **Functional correctness**: Classical pairs $(54,24)$, $(270,192)$, Fibonacci worst-case sketch, powers of two, small primes.
* **Recursive / binary agreement**: Grid cross-check of `Gcd_Recursive` and `Binary_Gcd` against iterative `Gcd`.
* **LCM / coprimality / steps**: Educational identities; `Max_Educational = 10^6`.
* **Contract discipline**: Oversized LCM is rejected by `Pre` (no exception path).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Subprogram_Variant`.
* Remainder loops use `pragma Loop_Variant`; recursive gcd uses `Subprogram_Variant (Decreases => B)`.
* **GNATprove Level 4:** `Success: all checks proved (70 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
