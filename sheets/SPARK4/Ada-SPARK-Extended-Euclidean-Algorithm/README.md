# Extended Euclidean Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [extended Euclidean algorithm](https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm): given nonnegative integers $a$ and $b$, compute $g=\gcd(a,b)$ together with Bézout coefficients $x,y$ such that

$$
a x + b y = \gcd(a,b)
$$

Written in Ada 2022 and verified with SPARK (GNATprove Level 4). The package also offers quotients $a/g$ and $b/g$, coprimality, and modular multiplicative inverse when $\gcd(a,m)=1$ (via Bézout).

This is the SPARK Level 4 port of the companion package [Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses the shorter package name `Extended_Euclidean`, signed `Long_Integer` operands with `Abs_LI`, and `Invalid_Argument` for invalid modular inverse; this port trades those for a nonnegative `Educational` domain (`0 .. Max_Educational`), contracts, and machine-checkable absence of run-time errors. Closest SPARK sibling: [Ada-SPARK-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Euclidean-Algorithm) (classical gcd / LCM). Related: [Ada-SPARK-Blum-Blum-Shub](https://github.com/RobertBoettcherSF/Ada-SPARK-Blum-Blum-Shub) (Gcd helpers). README only — do not `with` those packages here.

Note: a spreadsheet row title may say “Euclidian”; Wikipedia spelling is **Euclidean**.

## Features
* **`Gcd` / `Extended_Gcd`**: Classical and extended Euclidean gcd (iterative Wikipedia form). $\gcd(0,0)=0$. Bézout coefficients may be negative.
* **`Verify_Bezout`**: Classroom check of $a x + b y = g$ (used extensively by tests).
* **`Quotients_By_Gcd` / `Are_Coprime`**: $a/g$, $b/g$, and coprimality.
* **`Modular_Inverse` / `Is_Modular_Inverse`**: $a^{-1} \bmod m$ when $\gcd(a,m)=1$ and $a < m$ (Pre replaces exceptions).
* **`Divides` / `Mod_Nonneg`**: Helpers for contracts and tests.
* **Formal Verification**: GNATprove Level 4 — absence of division-by-zero, non-termination of remainder loops, and overflow on educational-sized coefficient updates.
* **Contract Discipline**: Preconditions replace exceptions; invalid inverse is a `Pre` violation rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* Nonnegative `Educational` (`0 .. Max_Educational`) replaces signed `Long_Integer` / `Abs_LI`.
* No exceptions: modular-inverse domain guard is `Pre => M > 1 and A < M and Are_Coprime(A, M)`.
* Package name `Extended_Euclidean_Algorithm` (files `extended_euclidean_algorithm.*`) for SPARK-series consistency; non-SPARK sibling keeps the shorter `Extended_Euclidean` name.
* `Max_Educational = 10^3` (vs $10^6$ in the non-SPARK sibling) so classroom products fit in `Integer`.
* `Extended_Gcd` Post covers zero-cases and positivity; Bézout $a x + b y = g$ is validated by tests (`Verify_Bezout`) rather than a Level 4 Post (full inductive coefficient-bound lemmas are beyond automatic classroom reach — same discipline as Ada-SPARK-Euclidean-Algorithm omitting full Divides/“greatest” Posts).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 1946 assertions pass. Running `make prove` reports `Success: all checks proved (85 checks).`

## Testing
* **Functional correctness**: Wikipedia pairs $(240,46)$, $(54,24)$, $(270,192)$, zero-cases, educational primes.
* **Bézout grid**: Pairwise identity check across many educational pairs.
* **Modular inverse / quotients / coprimality**: Educational identities; invalid inverse paths are Pre violations (no exception path).
* **Bound**: `Max_Educational = 10^3`.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global` / `Loop_Variant`.
* Remainder / extended loops use `pragma Loop_Variant`; coefficient updates go through an educational-sized helper so overflow VCs close.
* **GNATprove Level 4:** `Success: all checks proved (85 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
