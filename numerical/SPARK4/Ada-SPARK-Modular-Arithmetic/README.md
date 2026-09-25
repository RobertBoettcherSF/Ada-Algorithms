# Ada-SPARK-Modular-Arithmetic

Version 0.001. A proved Ada 2022 / SPARK library for modular arithmetic:
ring operations that cannot overflow for any modulus up to 2**63-1,
square-and-multiply powers, extended Euclid and inverses, the Chinese
Remainder Theorem, Montgomery multiplication, and check digits (IBAN, ISBN-10,
EAN-13/ISBN-13, Luhn) built on top of them.

## Project Overview

Modular arithmetic is "clock arithmetic". You pick a modulus N and only
keep the remainder after dividing by N, so numbers wrap around once they
reach N. On a 12-hour clock, 9 + 5 = 2, because 14 leaves remainder 2 when
divided by 12. Adding, subtracting and multiplying remainders gives the same
answer as doing the work on the full numbers and taking the remainder at the
end. That is why the method turns up in hashing, cryptography, calendars and
check digits. An element A has an *inverse* (a number B with A * B = 1 mod N)
exactly when A and N have no common factor, i.e. gcd(A, N) = 1. If N is split
into coprime factors, the Chinese Remainder Theorem says a number below N is
fixed by its remainders modulo those factors.
Background: https://en.wikipedia.org/wiki/Modular_arithmetic

## Features / API

All values are `Natural_64` (0 .. 2**63-1), and moduli are `Modulus_Type`
(2 .. 2**63-1). Intermediate products use a 128-bit signed integer type
`Wide`, so they never overflow. Every function carries a contract that states
its result in ordinary integer mathematics, and GNATprove checks those
contracts.

| Unit | Subprogram | Contract (Post) |
|------|-----------|-----------------|
| `Modular_Arithmetic` | `Reduce (A, N)` | `= A mod N` |
| | `Add_Mod`, `Sub_Mod`, `Neg_Mod` (A, B < N) | `= (A+B) mod N`, `(A-B) mod N`, `(-A) mod N`; no wide type needed |
| | `Mul_Mod (A, B, N)` | `= (A*B) mod N`, 128-bit product |
| | `Pow_Mod (B, E, N)` | `= Pow_Spec (B, E, N)`, square-and-multiply, O(log E) |
| | `Extended_Gcd (A, B)` | `G = gcd`, `A*X + B*Y = G`, G divides A and B, bounded X, Y |
| | `Gcd`, `Is_Unit (A, N)` | `Is_Unit = (gcd (A, N) = 1)` |
| | `Inverse (A, N)` (Pre: gcd = 1) | `Inv < N`, `(A * Inv) mod N = 1` |
| | `Orbit_Length (A, N)` | `= N / gcd (A, N)`: number of distinct multiples of A mod N (`Result * gcd = N`, `Result * A = 0 mod N`) |
| | `Multiplicative_Order (A, N)` | least K >= 1 with A**K = 1 (mod N), or 0 if A is not a unit; linear search, meant for small N |
| `Modular_Arithmetic.Ring` | generic `(Modulus)`: `Residue`, `Reduce`, `Add`, `Sub`, `Neg`, `Mul`, `Pow`, `Is_Unit`, `Inverse`, `Orbit_Length`, `Order` | same contracts, specialised to one modulus |
| `Modular_Arithmetic.Big_Ring` | `Ring (2**63 - 25)` | instance at the top of the range (largest prime < 2**63) |
| `Modular_Arithmetic.CRT` | `Crt2 (R1, M1, R2, M2)` | `X < M1*M2`, `X mod M1 = R1`, `X mod M2 = R2` |
| | `Lemma_Crt2_Unique` (ghost) | two solutions below M1*M2 are equal (uniqueness) |
| | `Crt_Array (C)` (1 .. 64 congruences, `Pairwise_Coprime`, `Product_Fits`) | `X < product`, `X mod M(i) = R(i)` for all i |
| `Modular_Arithmetic.Montgomery` | `Make_Context (N)` (odd N < 2**62) | `N * N' = -1 (mod R)`, `R * R^-1 = 1 (mod N)`, R = 2**62 |
| | `Redc (T, C)` | `Result * R = T (mod N)`, `Result < N` |
| | `To_Montgomery`, `From_Montgomery`, `Montgomery_Multiply` | `A*R mod N`, `X*R^-1 mod N`, `X*Y*R^-1 mod N` |
| | `Multiply (A, B, C)` | `= Mul_Mod (A, B, N)` |
| `Modular_Arithmetic.Check_Digits` | `Iban_Valid`, `Iban_Check_Digits` | ISO 13616 / ISO 7064 mod 97-10 |
| | `Isbn10_Valid`, `Isbn10_Check_Digit` | mod 11, weights 10..1, `X` = 10 |
| | `Ean13_Valid`, `Isbn13_Valid`, `Ean13_Check_Digit` | mod 10, weights 1/3; ISBN-13 needs prefix 978/979 |
| | `Luhn_Valid`, `Luhn_Check_Digit` | Luhn mod 10 |

Uniqueness (CRT): if the moduli are pairwise coprime, exactly one X with
0 <= X < M1 * ... * Mk satisfies all the congruences. Every other integer
solution differs from it by a multiple of the product. `Crt2` and `Crt_Array`
return this smallest solution. For two moduli the uniqueness is proved
(`Lemma_Crt2_Unique`) and tested (REQ-015).

## Usage

```ada
with Modular_Arithmetic; use Modular_Arithmetic;
with Modular_Arithmetic.Ring;
with Modular_Arithmetic.Check_Digits;
...
package Z97 is new Modular_Arithmetic.Ring (97);
X : constant Z97.Residue := Z97.Mul (Z97.Reduce (1234), 5);
P : constant Natural_64  := Pow_Mod (3, 1_000_000, 2**63 - 25);
I : constant Natural_64  := Inverse (3, 7);                        --  5
Ok : constant Boolean :=
  Modular_Arithmetic.Check_Digits.Iban_Valid ("DE89 3704 0044 0532 0130 00");
```

## Requirements

| ID | Requirement |
|----|-------------|
| REQ-001 | `Reduce (A, N) = A mod N` |
| REQ-002 | `Add_Mod = (A + B) mod N`, no overflow for any N <= 2**63-1 |
| REQ-003 | `Sub_Mod = (A - B) mod N`, result in 0 .. N-1 |
| REQ-004 | `Neg_Mod = (-A) mod N` |
| REQ-005 | `Mul_Mod = (A * B) mod N`, no overflow for any N <= 2**63-1 |
| REQ-006 | `Pow_Mod = B**E mod N` (square-and-multiply, 0**0 = 1) |
| REQ-007 | `Extended_Gcd` returns Bezout coefficients: A*X + B*Y = gcd, bounded |
| REQ-008 | `Gcd` is the greatest common divisor (gcd(0,0) = 0) |
| REQ-009 | `Is_Unit (A, N)` iff gcd (A, N) = 1 |
| REQ-010 | `Inverse`: A * Inverse (A) = 1 mod N for units |
| REQ-011 | `Orbit_Length (A, N) = N / gcd (A, N)` = number of distinct multiples |
| REQ-012 | `Multiplicative_Order` = least K >= 1 with A**K = 1, 0 for non-units |
| REQ-013 | `Crt2`: X mod M1 = R1, X mod M2 = R2, 0 <= X < M1*M2 |
| REQ-014 | `Crt_Array`: X mod Mi = Ri for all i, 0 <= X < product |
| REQ-015 | CRT solution below the product is unique |
| REQ-016 | `Make_Context`: valid Montgomery constants for odd N < 2**62 |
| REQ-017 | `Redc`, `To_Montgomery`: Montgomery reduction / conversion correct |
| REQ-018 | Montgomery `Multiply` = `Mul_Mod`; From (To (A)) = A |
| REQ-019 | IBAN mod 97-10 validation and check-digit generation |
| REQ-020 | ISBN-10 mod 11 validation (incl. X) and check digit |
| REQ-021 | EAN-13 / ISBN-13 mod 10 (weights 1/3) validation and check digit |
| REQ-022 | Luhn validation and check digit |
| REQ-023 | Generic `Ring` instances (small N and N = 2**63-25) behave as the base operations |
| REQ-024 | Builds with 0 warnings under `-gnatwa` on GNAT 14 and GNAT 12, also from a git-less copy |
| REQ-025 | All SPARK checks proved by GNATprove at `--level=4` (reached 1629/1629 before proofs were paused on 2026-09-25; see Proof Status) |

Every check in `tests.adb` is labelled with the REQ ID it covers. REQ-001 to
REQ-023 are covered by tests. REQ-015 is also proved as a lemma. REQ-024 is
checked by building, and REQ-025 by `make prove`.

## Testing

Reference values are computed independently. Small moduli are checked
exhaustively against brute force. Large moduli (up to 2**63-1) are checked
against `Interfaces.Unsigned_128` arithmetic and against Fermat's little
theorem for the primes 2**63-25 and 2**61-1. The check-digit tests use
published valid examples, each of which is re-verified by the algorithm
itself:

* IBAN: DE89 3704 0044 0532 0130 00, GB82 WEST 1234 5698 7654 32,
  GB29 NWBK 6016 1331 9268 19, FR14 2004 1010 0505 0001 3M02 606,
  NL91 ABNA 0417 1643 00, BE68 5390 0754 7034, CH93 0076 2011 6238 5295 7,
  NO93 8601 1117 947, AT61 1904 3002 3457 3201, IT60 X054 2811 1010 0000 0123 456
* ISBN-10: 0-306-40615-2, 99921-58-10-7, 0-8044-2957-X, 3-16-148410-X,
  0-19-853453-1, 1-84356-028-3
* EAN-13 / ISBN-13: 978-0-306-40615-7, 978-3-16-148410-0, 4006381333931,
  978-1-86197-876-9, 5901234123457, 9780262033848
* Luhn: 79927398713 and the standard test card numbers 4111 1111 1111 1111,
  4012 8888 8888 1881, 3782 822463 10005, 5555 5555 5555 4444,
  6011 1111 1111 1117

Each example is then mutated. Every single-digit substitution must be
rejected. Every adjacent transposition must be rejected, except where the
scheme is known to miss it: EAN-13 misses swaps of digits that differ by 5,
and Luhn misses 09 <-> 90. The tests check those exceptions exactly.

```
make test                   # GNAT 14 (gnatmake)
make test GNAT=gnatmake-12  # GNAT 12
```

Result: **138 checks, 0 failed** on GNAT 14 and on GNAT 12 (with
`-gnata`, so contracts are also checked at run time).

### Mutation testing

`make mutate` builds `tools/mutate.adb`, a small Ada mutation tool (no
scripts). It copies the sources to `mutate_work/` and makes one change at a
time in the four core bodies (`modular_arithmetic.adb`, `-crt.adb`,
`-montgomery.adb`, `-check_digits.adb`):

* relational, logical and arithmetic operator swaps
* negated conditions
* integer literal +/- 1

Ghost code, lemma calls and pragmas are skipped. Each mutant is rebuilt
without `-gnata`, so the tests have to catch it rather than the contracts,
and then the test suite runs with a time-out. Mutants that were reviewed by
hand and shown to be equivalent (they cannot change behaviour) are listed
with a reason in `tools/mutation_equivalent.txt` and are not counted.

Result (2026-09-25, GNAT 14): 231 mutants in total.

| Outcome | Count |
|---------|------:|
| Compiled mutants | 202 |
| Killed by the tests (5 by time-out) | 202 |
| Survived | 0 |
| Stillborn (did not compile, not counted) | 20 |
| Equivalent (reviewed, not counted) | 9 |
| **Kill rate** | **100.0 %** (202 / 202) |

Two earlier passes ended at 81 % and 95.8 %. The tests added after them are
tagged with the same REQ IDs:

* exhaustive and boundary checks
* orders at the largest modulus
* check digits of strings indexed up to `Integer'Last`


## Building

Requires GNAT (tested with GNAT 14 and GNAT 12) and `make`. There are no
scripts and no Alire manifest.

```
make                         # build bin/tests
make test                    # build and run the tests
make prove                   # gnatprove -P modular_arithmetic.gpr --level=4
make mutate                  # mutation pass
make clean
```

The sheet is also built and run by the monorepo harness
(`make test CAT=numerical` at the repository root).

## Proof Status

**State when proofs were paused (2026-09-25, about 10:46 CEST): 1629 / 1629
checks proved at `--level=4`** (GNATprove 16.1, `make prove`, 0 unproved,
0 justified). This is our own GNATprove run. No external badge is used.

| Category | Checks |
|----------|-------:|
| Data dependencies (flow) | 86 |
| Initialization (flow) | 32 |
| Run-time checks (overflow, range, index, division) | 919 |
| Assertions (proof hints) | 187 |
| Functional contracts (Pre/Post) | 325 |
| Termination (flow 75, provers 5) | 80 |
| **Total** | **1629** |

How to read this:

* **Proof runs are paused** (Robert's policy of 2026-09-25, to save
  compute). Nothing after that date has been re-proved.
* The total merges per-unit results. The last edits (hints in `CRT` and two
  small lemmas in `Lemmas`) were re-proved with `gnatprove -u`, and the other
  units come from the full run just before. One clean full `make prove` run
  is still needed to confirm the number.
* GNATprove does not analyse the library-level instance `Big_Ring`
  (N = 2**63-25), because the instantiation is outside SPARK_Mode. It is only
  tested. The Z/97, Z/11 and Z/10 instances used by `Check_Digits` are
  analysed.
* For `Check_Digits` only absence of run-time errors is proved. Its
  functional behaviour is covered by tests.
* Future proof work is tracked in [`PROOF_BACKLOG.md`](PROOF_BACKLOG.md). Each
  subprogram is marked in the source with
  `--  PROOF-LATER: Importance N/10, Urgency N/10, SPARKn` (or `Ada` when no proof is planned).


Proof technique: all arithmetic is carried out in the 128-bit type `Wide`.
Facts about `mod` are proved once as ghost lemmas in
`Modular_Arithmetic.Lemmas` (uniqueness of division with remainder,
associativity of multiplication mod N, and so on) and applied explicitly.
`Pow_Spec` is a recursive ghost definition (halving the exponent), and
`Pow_Mod` is proved equal to it. The check-digit package is proved free of
run-time errors (no overflow, no index errors). Its functional behaviour is
covered by the tests.

## Limits and deviations

* Largest modulus: 2**63-1 (`Modulus_Type`). Montgomery uses R = 2**62, so
  it needs an odd modulus below 2**62.
* CRT: the product of all moduli must be at most 2**63-1, and there can be at
  most 64 congruences.
* `Multiplicative_Order` is a linear search (O(N) worst case), meant for
  small moduli.
* `Pow_Mod` is recursive, with a proved `Subprogram_Variant` and recursion
  depth log2(E) <= 63, not a loop. GNATprove could not reason about `2**K`
  in the loop invariant of the iterative version.
* IBAN: only the characters and the mod 97-10 checksum are checked (length 5
  .. 34, spaces ignored, lower case accepted). Country-specific lengths and
  BBAN formats are not checked.
* GNAT 12 has a bug with `Subprogram_Variant` on recursive expression
  functions under `-gnata`. The work-around is
  `pragma Assertion_Policy (Subprogram_Variant => Ignore)`: GNATprove still
  proves the variants, they are just not checked at run time.

## License

MIT, see `LICENSE`.
