# Spaghetti Sort in Ada 2023

## Project Overview

**Spaghetti sort** is a linear-time *analog* sorting algorithm introduced by
**A. K. Dewdney** in his *Scientific American* Computer Recreations column.
The physical story is simple: for each key, cut an uncooked spaghetti rod to
that length; hold the rods loosely in a fist and stand them upright on a
table; then repeatedly lower a hand from above until it touches the tallest
remaining rod, remove that rod, and place it into the output. With parallel
“hardware” (hand, rods, and table), finding the current maximum is treated as
$O(1)$, so the whole procedure is $O(n)$ time and $O(n)$ stack/space, and can
be arranged to be stable.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** *educational software
simulation* of that idea. A conventional sequential computer cannot lower a
hand onto $n$ rods in constant time, so the simulations here are honest about
their asymptotic cost:

| Method | Idea | Software cost |
| --- | --- | --- |
| `Sort` / `Sort_Height` | Place nonnegative keys into “height” bins (counting) | $O(n + U)$ with universe $U = \texttt{Max\_Key}+1$ |
| `Sort_Extraction` | Repeatedly extract the current maximum (selection-like) | $O(n^2)$ |

Primary source: [Wikipedia — Spaghetti sort](https://en.wikipedia.org/wiki/Spaghetti_sort).

## Features

- **Height-bin primary API** — `Sort` tallies rod lengths in $0..\texttt{Max\_Key}$
  and emits a stable ascending sequence (short rods first).
- **Max-extraction variant** — `Sort_Extraction` works for general `Integer`
  keys (negative, zero, positive) by simulating Dewdney’s “pull the tallest”
  loop without parallel hardware.
- **`Is_Sorted` helper** — nondecreasing predicate for empty, singleton, and
  multi-element arrays.
- **Capacity guards** — `Invalid_Argument` when length exceeds `Max_Length`,
  or when height-bin keys fall outside $0..\texttt{Max\_Key}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pspaghetti_sort.gpr`.

## Analog algorithm (history)

Dewdney’s illustration assumes natural-number keys. Preparing $n$ rods takes
linear time; resting them on the table is $O(1)$ because the physical setup
acts as a fully parallel device; each contact-and-removal is assumed $O(1)$,
so $n$ removals yield $O(n)$ overall. Software ports that scan for a maximum
each step recover classical selection-sort behavior ($O(n^2)$). Mapping keys
into an explicit height array recovers counting-sort / pigeonhole behavior
($O(n+U)$), which is the clearest classroom stand-in for “rod length =
array index.”

## Complexity caveats

- **True spaghetti sort** (analog / parallel): $O(n)$ time under the model
  that $\max$ of $n$ rods is $O(1)$.
- **This package**: sequential simulation only — either $O(n^2)$ extraction or
  $O(n+U)$ height bins. Do **not** claim $O(n)$ wall-clock time on a
  single-threaded CPU.
- **Stability**: height-bin `Sort` is stable for equal integer keys; extraction
  uses a rightmost-max tie break so the final ascending reverse preserves
  relative order of equal values.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...
=== 1. Empty and singleton ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

## API sketch

```ada
package Spaghetti_Sort is
   Max_Length : constant Positive := 10_000;
   Max_Key    : constant Natural  := 10_000;

   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;

   procedure Sort (A : in out Element_Array);            -- height bins
   procedure Sort_Height (A : in out Element_Array);     -- rename of Sort
   procedure Sort_Extraction (A : in out Element_Array); -- general Integers
   function  Is_Sorted (A : Element_Array) return Boolean;
end Spaghetti_Sort;
```

## Testing

`tests.adb` covers empty/singleton cases, duplicates, reversed and mixed
permutations, signed keys for extraction, agreement between both methods on
nonnegative data, deterministic pseudo-random arrays versus an insertion-sort
reference, `Invalid_Argument` for oversize / out-of-range keys, non-1-based
index bounds, idempotence, and `Max_Key` boundary values. Target: many PASS,
zero FAIL.

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## References

- A. K. Dewdney, Computer Recreations, *Scientific American* (spaghetti sort).
- https://en.wikipedia.org/wiki/Spaghetti_sort
