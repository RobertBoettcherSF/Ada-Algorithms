# Library Sort in Ada 2023

## Project Overview

**Library sort** (also called *gapped insertion sort*) is a comparison
sorting algorithm proposed by **Michael A. Bender**, **Martín
Farach-Colton**, and **Miguel Mosteiro** (2004; published 2006). It is
insertion sort with **blank spaces** left in a larger working array so
that most insertions only shift a short run of keys until the next gap,
instead of sliding an entire suffix.

### Librarian shelf analogy

Imagine a librarian shelving books A–Z with **no** empty slots: inserting
a new B may require shifting every book from mid-B through Z. If the
librarian leaves a blank after every letter, a new B usually needs only a
few books moved until the next blank — the idea behind library sort.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for `Integer` arrays with bound `Max_N = 8192`. The gap
factor is $\varepsilon = 1$, so the working capacity is

$$
\mathrm{Cap}(n) = (1+\varepsilon)\,n = 2n.
$$

Primary source:
[Wikipedia — Library sort](https://en.wikipedia.org/wiki/Library_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Allocate a working array $W[1..\mathrm{Cap}]$ of empty **gaps**,
   $\mathrm{Cap} = 2n$.
3. Place $A$'s first element into $W$; then for each remaining element $x$:
   - On **doubling rounds** (after $1, 2, 4, \ldots$ insertions),
     **rebalance**: gather occupied values and **spread** them evenly
     across $W$ so gaps reopen between keys.
   - **Binary-search** $W$ for an insertion index (if the midpoint is a
     gap, scan right then left for a nearest occupied neighbour).
   - **Insert** $x$ into a gap at that index, or shift occupied slots
     until a gap is hit. If a local region has no gap, rebalance and
     retry.
4. **Pack** occupied slots of $W$ left-to-right back into $A$.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Rebalance (spread)

After gathering $k$ occupied values into a dense buffer, place element
$j$ (1-based) at index

$$
1 + (j-1)\left\lfloor\frac{\mathrm{Cap}}{k}\right\rfloor
$$

(walking forward on rare collisions). For $\varepsilon = 1$ and
$k \approx n$, this is roughly every other slot — half gaps, half keys.

### Example

Sort $A = [4, 1, 3]$ with $\varepsilon = 1$ ($\mathrm{Cap} = 6$):

```text
  place 4 → W ≈ [4, _, _, _, _, _]
  rebalance (k=1) → [4, _, _, _, _, _]
  insert 1 → binary search, place in a gap / short shift
  insert 3 → …
  pack     → A = [1, 3, 4]
```

(Exact gap indices depend on the spread step; the packed result is the
nondecreasing permutation of $A$.)

## Complexity

| Measure | Bound | Notes |
| ------- | ----- | ----- |
| Time (average, suitable $\varepsilon$) | $O(n \log n)$ w.h.p. | Bender et al.; binary search per insert + cheap shifts |
| Time (worst) | closer to insertion sort | adversarial order / congestion; more shifts & rebalances |
| Rebalance total | $O(n)$ across doubling rounds | each element moved $O(1)$ times amortized on the schedule |
| Auxiliary space | $\Theta((1+\varepsilon)n)$ | working buffer of gaps + keys |
| Stability | **No** | equal keys may reorder |
| Online / adaptive | **No** (this body) | paper uses random permutation for the high-prob. bound |

This educational body **does not** randomly shuffle the input (clarity
over the probabilistic guarantee). It remains a correct comparison sort.

## Features

- **`Sort (A)`** — ascending library sort on `Integer` arrays ($\varepsilon = 1$).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **Gapped working buffer** — $\mathrm{Cap} = 2n$ slots with rebalance.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $8192$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain (not stable).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Plibrary_sort.gpr`.

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
- Already-sorted / reverse / almost-sorted / alternating patterns
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys (value order vs insertion-sort reference)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference
- Power-of-two and odd lengths
- Idempotence (sorting twice)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Library_Sort is
   Max_N : constant Positive := 8_192;
   Epsilon_Numerator   : constant Positive := 1;
   Epsilon_Denominator : constant Positive := 1;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Library_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
