# Introsort in Ada 2023

## Project Overview

**Introsort** (introspective sort) is a **hybrid** comparison sorting
algorithm invented by **David Musser** (1997). It begins with **quicksort**,
switches to **heapsort** when the recursion depth exceeds a bound based on
$\lfloor\log_2 n\rfloor$, and finishes small partitions with **insertion
sort**. The combination keeps practical performance close to tuned quicksort
on typical data while guaranteeing

$$
O(n \log n)
$$

in the worst case (via the heapsort fallback). Introsort is **in-place** and
**not stable**.

Variants of introsort power many standard-library unstable sorts (GNU
libstdc++ `std::sort`, LLVM libc++, Microsoft .NET Framework 4.5+, and
others). Pattern-defeating quicksort (pdqsort) is a well-known descendant.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic Musser introsort for `Integer` arrays: median-of-
three quicksort partitioning, depth limit $2\lfloor\log_2 n\rfloor$, heapsort
on exhausted depth, and insertion sort for partitions of size
$\le 16$. All helpers are **inlined** — the package does not `with` sibling
`Heapsort` or `Insertion_Sort` projects.

Primary source: [Wikipedia — Introsort](https://en.wikipedia.org/wiki/Introsort).

## Algorithm

Given an array $A$ of length $n$:

1. **Depth budget.** Set

   $$
   \mathrm{maxdepth} \leftarrow 2 \lfloor \log_2 n \rfloor.
   $$

   The factor $2$ is the classic Musser / SGI / GNU libstdc++ choice; it can
   be tuned for practical performance.

2. **Introsort recursion** on a partition of length $m$:

   - If $m \le \mathrm{Insertion\_Threshold}$ (here $16$): finish with
     **insertion sort**.
   - Else if $\mathrm{maxdepth} = 0$: sort the partition with **heapsort**
     (Floyd heapify + extract-max). This caps the worst case at
     $O(n \log n)$.
   - Else: **median-of-three** pivot (first / middle / last), **Hoare
     partition**, then recurse on both sides with $\mathrm{maxdepth}-1$.

3. Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
   raises `Invalid_Argument`.

Pseudocode (adapted from Wikipedia; 1-based sketch):

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{sort}(A): \\
&\quad \mathrm{maxdepth} \leftarrow \lfloor\log_2(\mathrm{length}(A))\rfloor \times 2 \\
&\quad \mathrm{introsort}(A,\ \mathrm{maxdepth}) \\[0.5em]
&\mathbf{procedure}\ \mathrm{introsort}(A,\ \mathrm{maxdepth}): \\
&\quad n \leftarrow \mathrm{length}(A) \\
&\quad \mathbf{if}\ n < 16:\ \mathrm{insertionsort}(A) \\
&\quad \mathbf{else\ if}\ \mathrm{maxdepth} = 0:\ \mathrm{heapsort}(A) \\
&\quad \mathbf{else}: \\
&\quad\quad p \leftarrow \mathrm{partition}(A) \\
&\quad\quad \mathrm{introsort}(A[1:p],\ \mathrm{maxdepth}-1) \\
&\quad\quad \mathrm{introsort}(A[p+1:n],\ \mathrm{maxdepth}-1)
\end{align*}
$$

(This Ada package uses an inclusive Hoare split; the Wikipedia sketch shows
a Lomuto-style exclusive pivot index — both are valid introsort shapes.)

## Why the hybrid?

| Ingredient | Role |
| ---------- | ---- |
| Quicksort (median-of-3 + Hoare) | Fast average case, good locality |
| Depth-limited heapsort | Prevents $O(n^2)$ on adversarial / killer sequences |
| Insertion sort ($m \le 16$) | Optimal for tiny partitions; fewer overheads |

Musser reported that on a median-of-3 killer sequence of $10^5$ elements,
introsort ran about $200\times$ faster than plain median-of-3 quicksort.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average | $O(n \log n)$ | $O(\log n)$ stack |
| Worst | $O(n \log n)$ (heapsort fallback) | $O(\log n)$ stack |
| Tiny partition | $O(m^2)$ insertion, $m \le 16$ | $O(1)$ |

Unstable: equal keys may change relative order.

## Features

- **`Sort (A)`** — ascending in-place introsort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`.
- **Thresholds** — `Insertion_Threshold = 16`, depth $= 2\lfloor\log_2 n\rfloor$.
- **Arbitrary bounds** — works for any `A'First` (First-relative heap math).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pintrosort.gpr`.

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
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 80.)

## Testing

The suite in `tests.adb` covers:

- Empty, singleton, and two-element arrays
- Already sorted, fully reversed, and duplicate-heavy inputs
- Negatives and `Integer'First` / `Integer'Last`
- Non-1-based index bounds (0-based, 5-based, 10-based)
- Sizes on both sides of the insertion threshold ($15$, $16$, $17$, …)
- Adversarial patterns: sorted, all-equal, sawtooth, organ-pipe
- Random arrays of many lengths matched against an insertion-sort reference
- Oversize arrays raising `Invalid_Argument`
- Idempotence of `Sort`
- Large reverse / random arrays ($n = 1024$, $2048$) exercising depth limits

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Max_N` | Educational capacity bound (`100_000`) |
| `Insertion_Threshold` | Small-partition cutoff (`16`) |
| `Invalid_Argument` | Raised on oversize length |
| `Sort` | Ascending in-place introsort |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Introsort.
