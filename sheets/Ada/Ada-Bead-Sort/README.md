# Bead Sort in Ada 2023

## Project Overview

**Bead sort**, also called **gravity sort**, is a natural sorting algorithm
introduced by Joshua J. Arulanandham, Cristian S. Calude and Michael J. Dinneen
in 2002. It mirrors beads sliding down parallel poles on an abacus: each input
value $a_i$ places beads on poles $1 .. a_i$; gravity lets beads fall; the
settled rows read out the multiset in sorted order.

Digital and analog **hardware** implementations can achieve a sorting time of

$$
O(n)
$$

(or even abstract $O(1)$ if every bead moves in one step). In **software**,
there is no physical gravity: dropping beads costs work proportional to the
sum of the inputs (up to $O(n \cdot M)$ for maximum value $M$), and even the
best practical layouts still need

$$
O(n^2)
$$

space in the naïve grid view — or $O(M)$ rod counters in the column-count
simulation used here. Bead sort applies only to **nonnegative integers**.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational software
simulation with modest bounds (`Max_N = 1024`, `Max_Value = 1024`).

Primary source: [Wikipedia — Bead sort](https://en.wikipedia.org/wiki/Bead_sort).

## Algorithm

Given an array $A$ of length $n$ with nonnegative values and $M = \max A$:

1. Allocate rod counters $\mathrm{Rod}[1 .. M]$, initially zero.
2. For each $a_i > 0$, increment $\mathrm{Rod}[1], \ldots, \mathrm{Rod}[a_i]$
   (drop one bead on each of the first $a_i$ rods). Zero drops nothing.
3. Those counters already encode gravity: $\mathrm{Rod}[j]$ equals how many
   input values are $\ge j$ (settled height on rod $j$).
4. Reconstruct **ascending** order: for height $H = n$ downto $1$, the value
   at that row is the number of rods with $\mathrm{Rod}[j] \ge H$. Top rows
   have few beads (small values); the bottom row holds the largest.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$ or any
$a_i > \mathrm{Max\_Value}$, `Sort` raises `Invalid_Argument`.

### Example

For $A = [3, 2, 4, 2]$ the rod heights become $\mathrm{Rod} = [4, 4, 2, 1]$.
Reading rows $H = 4 .. 1$ yields bead counts $2, 2, 3, 4$ — sorted ascending.

## Complexity (hardware vs software)

| Model | Time | Space | Notes |
| ----- | ---- | ----- | ----- |
| Abstract simultaneous fall | $O(1)$ | $O(n \cdot M)$ grid | Not realizable as written |
| Physical gravity | $O(\sqrt{n})$ | physical rods | Fall time $\propto \sqrt{\text{height}}$ |
| Digital / analog hardware | $O(n)$ | rods / circuits | Row-by-row bead motion |
| **This software simulation** | $O(n \cdot M)$ | $O(M)$ counters | Each bead dropped individually |

Like pigeonhole / counting sort, bead sort can beat $O(n \log n)$ comparison
lower bounds because keys are nonnegative integers and the algorithm exploits
that structure — at the cost of value-dependent time and space.

## Relation to counting sort

$\mathrm{Rod}[j]$ is exactly the number of elements with value $\ge j$, the
same information a counting-sort histogram carries in cumulative form. Bead
sort presents that fact through the abacus metaphor; counting sort uses an
explicit count table and prefix sums. Sibling package: `ada-counting-sort`
(contrast only — this package does **not** `with` it).

## Features

- **`Sort (A)`** — ascending bead sort on `Natural` arrays (0 allowed).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guards** — `Invalid_Argument` when `A'Length > Max_N` or any
  value $> \mathrm{Max\_Value}$ (both default $1024$).
- **Arbitrary bounds** — works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbead_sort.gpr`.

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

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases
- Already-sorted, reverse, and mixed small inputs
- Zeros, duplicates, and all-equal arrays
- Non-1 `A'First` index bounds
- Random arrays vs insertion-sort reference
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n$ and oversize values
- Multiset equality vs reference sort

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bead_Sort is
   Max_N     : constant Positive := 1_024;
   Max_Value : constant Natural  := 1_024;
   type Element_Array is array (Natural range <>) of Natural;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Bead_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
