# Blum–Blum–Shub in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [Blum Blum Shub (BBS)](https://en.wikipedia.org/wiki/Blum_Blum_Shub) pseudorandom bit generator

$$
x_{n+1} = x_n^{2} \bmod M, \qquad M = p\,q
$$

with distinct Blum primes $p,q \equiv 3 \pmod{4}$ and seed $x_0$ coprime to $M$. Each step outputs the least significant bit (or a packed block of low bits) of the new state. Written in Ada 2022 and verified with SPARK (GNATprove Level 4).

This is the SPARK Level 4 port of the companion package [Ada-Blum-Blum-Shub](https://github.com/RobertBoettcherSF/Ada-Blum-Blum-Shub) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes unbounded modular words via `Unsigned_128` and `Invalid_Parameters` / `Invalid_Seed` exceptions; this port trades those for hard bounds (`Max_Prime = 2^{16}`, `Max_Modulus = 2^{32}`), contracts, and machine-checkable absence of run-time errors. For the same SPARK classroom style on sibling PRNGs, see [Ada-SPARK-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Linear-Congruential-Generator), [Ada-SPARK-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-ACORN-Generator), and [Ada-SPARK-Lagged-Fibonacci-Generator](https://github.com/RobertBoettcherSF/Ada-SPARK-Lagged-Fibonacci-Generator) (README only — do not `with` those packages here).

## Features
* **Create / Initialize / Reset / Next_Bit / Next_Byte / Next_Bits**: Classical BBS with initial state $\mathrm{seed}^{2} \bmod M$, then $x \leftarrow x^{2} \bmod M$ per bit.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of buffer overflows, modular wrap in the classroom modulus range, and non-termination of bounded loops.
* **Bounded State**: Static records only; no heap / no `Unbounded_*`.
* **Proveable Modular Arithmetic**: `Mul_Mod` / `Square_Mod` stay inside a single `mod 2**64` word for $M \le 2^{32}$.
* **Contract Discipline**: Preconditions replace exceptions; invalid primes / seeds are rejected by `Pre` / `Is_Valid_Blum_Pair` / `Is_Valid_Seed` rather than raised errors.
* **Educational Blum primes**: Named constants and `Small_Blum_Primes` table ($7,11,19,23,43,\ldots,547$) within `Max_Prime`, plus `Is_Prime` / `Is_Blum_Prime` / `Gcd` / `Are_Coprime`.

## Deliberate simplifications vs non-SPARK sibling
* Each Blum prime capped at `Max_Prime = 2**16` so $M = p\cdot q \le 2^{32} =$ `Max_Modulus` — $(M-1)^{2}$ fits without `Unsigned_128`.
* No exceptions: uninitialised / out-of-range uses are precondition violations (`Invalid_Parameters` / `Invalid_Seed` removed).
* `Next_Bit` / `Next_Byte` / `Next_Bits` are procedures `(G, Result)` rather than `in out` functions, matching SPARK-friendly styles in sibling packages (e.g. Ada-SPARK-ACORN-Generator).
* All of the package stays `SPARK_Mode => On` (no `Long_Float` unit variates).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 74 assertions pass. Running `make prove` reports `Success: all checks proved (261 checks).`

## Testing
* **Functional correctness**: Hand-computed bit sequence for $(p,q,x_0)=(11,19,3)$; tiny pair $(7,11)$; larger pair $(499,547)$.
* **Determinism**: Identical `Create` seeds, `Reset` replay.
* **Contract discipline**: Validation helpers cover rejected Blum pairs and seeds; invalid `Pre` cases are not raised as exceptions.
* **Mul_Mod / Square_Mod / Gcd**: Identities against $M=209$ and near `Max_Modulus`.
* **Educational table**: Every `Small_Blum_Primes` entry is Blum and $\le$ `Max_Prime`.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Depends`.
* Primality uses a bounded `for` loop up to $\lceil\sqrt{\mathtt{Max\_Prime}}\rceil = 256$; GCD uses `pragma Loop_Variant`.
* **GNATprove Level 4:** `Success: all checks proved (261 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
