# Linear Congruential Generator in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classical [linear congruential generator (LCG)](https://en.wikipedia.org/wiki/Linear_congruential_generator)

$$
X_{n+1} = (a\,X_n + c) \bmod m
$$

Written in Ada 2022 and verified with SPARK (GNATprove Level 4). Create / Reset seed a generator; each `Next` advances the state and returns $X_{n+1}$. Well-known parameter sets (Numerical Recipes, glibc / ANSI C, Borland, Park–Miller / MINSTD, RANDU, ZX81, …) and Hull–Dobell full-period helpers are included for classroom comparison.

This is the SPARK Level 4 port of the companion package [Ada-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-Linear-Congruential-Generator) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes unbounded modular words via `Unsigned_128`, `Long_Float` unit variates, and `Invalid_Argument` exceptions; this port trades those for hard bounds (`Max_Modulus = 2^{32}`), contracts, and machine-checkable absence of run-time errors. For the same SPARK classroom style on another PRNG, see the sibling [Ada-SPARK-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-ACORN-Generator) (README only — do not `with` that package here). Cycle-finding contrast: [Ada-SPARK-Floyds-Cycle-Finding-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Floyds-Cycle-Finding-Algorithm) and [Ada-SPARK-Brents-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Brents-Algorithm).

## Features
* **Create / Reset / Next / Step**: Classical mixed or multiplicative LCG with reduced $(A,C,M)$ stored in the generator.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, modular wrap in the classroom modulus range, and non-termination of bounded loops.
* **Bounded State**: Static records only; no heap / no `Unbounded_*`.
* **Proveable Modular Arithmetic**: `Add_Mod`, `Mul_Mod`, and the congruential step stay inside a single `mod 2**64` word for $M \le 2^{32}$.
* **Contract Discipline**: Preconditions replace exceptions; invalid inputs are rejected by `Pre` / `Is_Valid_Parameters` rather than raised errors.
* **Hull–Dobell helpers**: `Increment_Coprime`, `Multiplier_Condition`, `Four_Condition`, `Hull_Dobell_Satisfied`, plus `Gcd` / `Are_Coprime` / `Prime_Factors_Divide`.

## Deliberate simplifications vs non-SPARK sibling
* Modulus capped at `Max_Modulus = 2**32` so $(M-1)\cdot(M-1)+(M-1)$ fits without `Unsigned_128` (Java’s $2^{48}$ parameter set omitted).
* No `Next_Float` / `Long_Float` — integer `Next` only (all of the package stays `SPARK_Mode => On`).
* No exceptions: uninitialised / out-of-range uses are precondition violations.
* `Next` is a procedure `(G, Result)` rather than an `in out` function, matching SPARK-friendly styles in sibling packages (e.g. Ada-SPARK-ACORN-Generator).
* Published multipliers with $A \ge M$ (e.g. Visual Basic) are still accepted; `Create` / `Reduce` store $A \bmod M$ and $C \bmod M$.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 167 assertions pass. Running `make prove` reports `Success: all checks proved (192 checks).`

## Testing
* **Functional correctness**: Hand-computed tiny full-period sequences ($m=9$, $m=8$), counter / Weyl, Park–Miller / MINSTD, glibc, Numerical Recipes, Borland, MSVC, Delphi, VB, RANDU, ZX81.
* **Determinism**: Reset replay, identical independent generators, `Step` vs `Next`.
* **Contract discipline**: Validation helpers and valid-path coverage; invalid `Pre` cases are not raised as exceptions.
* **Hull–Dobell**: Component conditions and known full-period / MCG counter-examples.
* **Add_Mod / Mul_Mod / Gcd**: Wrap identities against `Default_Modulus` and small primes.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Depends`.
* Loops are bounded `for` loops (or `while` with `pragma Loop_Variant`) so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (192 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
