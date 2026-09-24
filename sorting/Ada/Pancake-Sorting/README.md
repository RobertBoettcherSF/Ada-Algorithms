# Pancake Sorting in Ada 2023

## Project Overview

**Pancake sorting** is the problem of sorting a disordered stack of pancakes by
size when the only allowed operation is a *prefix reversal* (a “flip”): a
spatula may be inserted anywhere in the stack and used to reverse every pancake
above it. The **pancake number** $P(n)$ is the minimum number of flips that
suffices to sort *any* stack of $n$ pancakes — equivalently, the diameter of
the $n$-pancake graph.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of the *classic* selection-style algorithm: for each prefix length
$n, n-1, \ldots, 2$, bring a maximum of that prefix to the front with one flip,
then flip it into its final position. That procedure uses at most $2n-3$ flips
for $n \ge 2$ (and none for $n \le 1$). It works on general `Integer` arrays,
including negatives and duplicates — not only permutations of $1..n$.

Primary source: [Wikipedia — Pancake sorting](https://en.wikipedia.org/wiki/Pancake_sorting).

## Prefix reversals

A prefix reversal of length $K$ reverses the first $K$ elements of the
sequence. On a 1-based array $A$, `Flip (A, K)` is exactly the reversal of
$A(1..K)$. This package uses **1-based logical / document bounds**: $K$ is a
prefix *length*, so on an array with any `A'First` the reversed slice is

$$
A\bigl(A'\mathrm{First} \;\ldots\; A'\mathrm{First}+K-1\bigr).
$$

$K = 0$ or $K = 1$ is a no-op. The only mutation the sorter performs is a
sequence of such flips.

## Pancake numbers

$P(n)$ is known exactly for $n \le 19$ ([OEIS A058986](https://oeis.org/A058986)):

| $n$ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| $P(n)$ | 0 | 1 | 3 | 4 | 5 | 7 | 8 | 9 | 10 | 11 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 22 |

The classic algorithm implemented here is *not* optimal in general; it only
guarantees

$$
P(n) \le 2n-3 \qquad (n \ge 2).
$$

Tighter asymptotic bounds on $P(n)$ are known:

$$
\frac{15}{14}n \;\le\; P(n) \;\le\; \frac{18}{11}n
$$

(approximately $1.07n$ and $1.64n$). Gates and Papadimitriou (1979) proved a
lower bound of $\frac{17}{16}n$ and an upper bound of $\frac{5n+5}{3}$; the
$\frac{18}{11}n$ upper bound is due to a University of Texas at Dallas team led
by Hal Sudborough. Finding a *shortest* flip sequence for a given stack is
NP-hard (Bulteau, Fertin, and Rusu, 2011).

A famous $n=3$ example from OEIS: $(1,3,2)$ requires $P(3)=3$ flips in the
worst-case sense. One optimal sequence is $(1,3,2) \to (3,1,2) \to (2,1,3) \to
(1,2,3)$.

## Classic algorithm (this package)

For size $n$ down to $2$:

1. Locate a maximum of the unsorted prefix of length $\textit{Size}$.
2. If it is already at position $\textit{Size}$, do nothing for this size.
3. Otherwise, if it is not already at the front, `Flip` the prefix that brings
   it to the front.
4. `Flip` the prefix of length $\textit{Size}$ so the maximum lands in its
   final slot.

At most two flips per size $n, n-1, \ldots, 3$ and at most one flip for size
$2$ yields the bound $2(n-2)+1 = 2n-3$. `Sort` may optionally record the
sequence of prefix lengths for tests; replaying those flips with `Apply_Flips`
reproduces the sorted array.

## Features

- **`Flip (A, K)`** — prefix reversal with 1-based logical bounds.
- **`Sort (A)`** — classic pancake sort, $\le 2n-3$ flips, general `Integer`s.
- **`Sort (A, Flips, Count)`** — same, recording the flip sequence.
- **`Apply_Flips`** — replay a recorded sequence of prefix reversals.
- **`Is_Sorted`** — nondecreasing predicate (empty and singleton included).
- **`Classic_Flip_Bound (N)`** — $0$ for $N \le 1$, else $2N-3$.
- **Capacity guards** — `Invalid_Argument` when length exceeds `Max_Length`,
  when $K$ exceeds the array length, or when a flip buffer is too small.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ppancake_sorting.gpr`.

## History (brief)

The problem was posed by Jacob E. Goodman under the pseudonym “Harry Dweighter”
(“harried waiter”). It is the subject of the only well-known mathematics paper
by Bill Gates (William Gates and Christos Papadimitriou, “Bounds for Sorting by
Prefix Reversal,” 1979). A burnt-pancake variant requires every pancake to end
burnt-side down (signed permutations); this package implements the unsigned
problem only.

Pancake graphs are Cayley graphs used as interconnection networks: $n!$
vertices (the permutations), degree $n-1$, edges given by prefix reversals.
Their diameter is exactly $P(n)$.

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
package Pancake_Sorting is
   Max_Length : constant Positive := 10_000;

   type Element_Array is array (Natural range <>) of Integer;
   type Flip_Sequence is array (Positive range <>) of Natural;
   Invalid_Argument : exception;

   procedure Flip (A : in out Element_Array; K : Natural);
   procedure Apply_Flips (A : in out Element_Array; Flips : Flip_Sequence);
   procedure Sort (A : in out Element_Array);
   procedure Sort
     (A     : in out Element_Array;
      Flips : out Flip_Sequence;
      Count : out Natural);
   function  Is_Sorted (A : Element_Array) return Boolean;
   function  Classic_Flip_Bound (N : Natural) return Natural;
end Pancake_Sorting;
```

## Testing

`tests.adb` covers empty/singleton cases, the `Flip` primitive, duplicates,
signed keys, reversed and mixed permutations, the $2n-3$ flip-count bound,
replay of recorded sequences, already-sorted zero-flip stacks, deterministic
pseudo-random arrays versus an insertion-sort reference, `Invalid_Argument` for
oversize arrays and tiny flip buffers, non-1-based index bounds, idempotence,
and the OEIS $n=3$ example $(1,3,2)$. Target: many PASS ($\ge 40$), zero FAIL.

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## References

- https://en.wikipedia.org/wiki/Pancake_sorting
- Gates, W.; Papadimitriou, C. (1979). “Bounds for Sorting by Prefix Reversal.”
- Bulteau, L.; Fertin, G.; Rusu, I. (2011). Pancake flipping is NP-hard.
- OEIS A058986 — maximum number of flips (pancake numbers).
- Weisstein, Eric W. “Pancake Sorting.” *MathWorld*.
