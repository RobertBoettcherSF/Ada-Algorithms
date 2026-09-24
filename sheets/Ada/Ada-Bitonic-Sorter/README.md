# Bitonic Sorter in Ada 2023

## Project Overview

A **sorting network** is a fixed comparator circuit: every wire between two
channels is a compare-and-swap that either exchanges its two values or leaves
them alone, and the topology does not depend on the data. **Batcher's bitonic
mergesort** builds such a network from *bitonic* subsequences.

A sequence is **bitonic** when it rises then falls (or is a cyclic shift of
that shape): there exists an index $m$ such that

$$
x_0 \le \cdots \le x_m \ge \cdots \ge x_{n-1}.
$$

A bitonic *sorter* turns a bitonic sequence into a fully sorted monotone
sequence. Recursively sorting the two halves of an arbitrary input into
opposite directions produces a bitonic whole; a bitonic merge then finishes
the sort. The resulting network uses

$$
\mathcal{O}\bigl(n(\log n)^{2}\bigr)
$$

comparators and has depth

$$
\mathcal{O}\bigl((\log n)^{2}\bigr),
$$

which makes it attractive on lockstep parallel hardware (classic GPUs).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** *sequential simulation* of
that network: recursive `Bitonic_Sort` / `Bitonic_Merge` with an ascending /
descending direction flag, matching the Wikipedia pseudocode.

Primary source: [Wikipedia — Bitonic sorter](https://en.wikipedia.org/wiki/Bitonic_sorter).

## Padding policy

The classical construction assumes $n = 2^{k}$. Rather than reject other
lengths, `Sort` **pads** to the next power of two with ascending sentinels
`Integer'Last`, runs the network on the padded buffer, then **trims** back to
the original length. Sentinel padding is friendlier for tests and matches the
mitigation noted on Wikipedia. Empty and singleton inputs are no-ops; lengths
above `Max_Length` raise `Invalid_Argument`.

## Algorithm (this package)

For a power-of-two work buffer $W$ of length $n$:

1. **`Bitonic_Sort(W, low, count, dir)`** — if $count > 1$, let
   $k = count/2$; recursively sort $[low .. low+k)$ ascending and
   $[low+k .. low+count)$ descending; then
   `Bitonic_Merge(W, low, count, dir)`.
2. **`Bitonic_Merge(W, low, count, dir)`** — pairwise
   `Compare_Swap` of $W(i)$ with $W(i+k)$ for $i \in [low .. low+k)$;
   recurse on both halves with the same direction.
3. Public **`Sort(A)`** copies $A$ into a $0$-based buffer, pads if needed,
   calls `Bitonic_Sort(..., Ascending => True)`, and writes the first
   $|A|$ values back.

`Compare_Swap(A, I, J, Ascending)` is the public single-wire primitive.

## Features

- **`Sort (A)`** — ascending bitonic mergesort network with sentinel padding.
- **`Compare_Swap (A, I, J, Ascending)`** — one sorting-network comparator.
- **`Is_Sorted`** — nondecreasing predicate (empty and singleton included).
- **`Next_Power_Of_Two` / `Is_Power_Of_Two`** — helpers documenting the pad.
- **Capacity guards** — `Invalid_Argument` when length exceeds `Max_Length`,
  or when `Compare_Swap` indices fall outside `A'Range`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbitonic_sorter.gpr`.

## Complexity

With $n = 2^{k}$ (after padding), each bitonic sorter of order $k$ contributes
$k$ parallel layers; summing over the construction gives depth
$\sum_{i=1}^{k} i = k(k+1)/2 = \mathcal{O}((\log n)^{2})$ and
$\mathcal{O}(n(\log n)^{2})$ comparators in total. This sequential package
executes those wires one after another, so wall-clock time on a single thread
is proportional to the comparator count, not the parallel depth.

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
type Element_Array is array (Natural range <>) of Integer;

procedure Compare_Swap
  (A : in out Element_Array; I, J : Natural; Ascending : Boolean);

procedure Sort (A : in out Element_Array);

function Is_Sorted (A : Element_Array) return Boolean;

function Next_Power_Of_Two (N : Natural) return Natural;
function Is_Power_Of_Two (N : Natural) return Boolean;
```

## License

Educational reference implementation. See upstream repository terms.
