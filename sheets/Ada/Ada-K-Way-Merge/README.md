# K-Way Merge in Ada 2023

## Project Overview

A **k-way merge** combines $k$ sorted lists into one sorted list. The classic
technique keeps a **binary min-heap** of the current head of each list; each
extract-min appends the next output element and may push the successor from
the same list. For a total of $N$ elements this costs

$$
O(N \log k)
$$

comparisons and moves — better fan-in than naïve repeated pairwise 2-way
merges when $k$ is large (those are still $O(N \log N)$ in a balanced
tournament, but with larger constants and less explicit control of $k$).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for ascending `Integer` sequences with modest bounds
(`Max_K = 64`, `Max_Len = 10_000` per list, `Max_Total = 100_000`).

Primary source: [Wikipedia — K-way merge algorithm](https://en.wikipedia.org/wiki/K-way_merge_algorithm).

## Algorithm

Represent each live list head as a heap node $(\mathit{value}, \mathit{list},
\mathit{index})$. Then:

1. Validate $k \le \mathrm{Max\_K}$, each list length $\le \mathrm{Max\_Len}$,
   total length $\le \mathrm{Max\_Total}$, and that every list is sorted
   ascending (`Is_Sorted`).
2. Insert the first element of every **non-empty** list into a binary
   **min-heap** (size at most $k$).
3. While the heap is non-empty:
   - extract the minimum head and append its value to the output;
   - if that list still has a next element, push the successor head.
4. After $N$ extract-mins the output is fully sorted of length $N$.

Empty lists and null accesses contribute nothing. $k = 0$ yields an empty
result. A separate **2-way** scan (`Merge (A, B)`) is provided for the
$k = 2$ special case without a heap.

### Example

Lists $[1,4,7]$, $[2,5,8]$, $[3,6,9]$ seed the heap with heads $1,2,3$.
Repeated extract-min produces

$$
1,2,3,4,5,6,7,8,9
$$

with heap size never exceeding $3$.

## Complexity

| Approach | Time | Extra space | Notes |
| -------- | ---- | ----------- | ----- |
| Heap of heads (this package) | $O(N \log k)$ | $O(k)$ heap + $O(N)$ output | Preferred for large $k$ |
| Balanced pairwise 2-way tree | $O(N \log N)$ | $O(N)$ temps | Independent of explicit $k$ |
| Naïve “merge into accumulator” | often worse constants | $O(N)$ | Still polynomial |

## Features

- **`Merge (Lists)`** — k-way merge via binary min-heap of heads; returns a
  new `Vector`.
- **`Merge (A, B)`** / **`Merge (A, B, Output, Last)`** — educational 2-way
  merge (function and stack-friendly procedure).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity / validity guards** — `Invalid_Argument` when $k$ is too large,
  a list is longer than `Max_Len`, the total exceeds `Max_Total`, any list is
  unsorted, or a 2-way `Output` buffer is too short.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pk_way_merge.gpr`.

## API sketch

```ada
type Vector is array (Positive range <>) of Integer;
type Vector_Access is access constant Vector;
type Vector_List is array (Positive range <>) of Vector_Access;

function Is_Sorted (A : Vector) return Boolean;
function Merge (Lists : Vector_List) return Vector;
function Merge (A, B : Vector) return Vector;
procedure Merge (A, B : Vector; Output : out Vector; Last : out Natural);
```

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
Results: <N> PASS, 0 FAIL
```

with $N \ge 50$.

## Project Layout

| File | Role |
| ---- | ---- |
| `k_way_merge.ads` / `.adb` | Package `K_Way_Merge` |
| `k_way_merge.gpr` | GNAT project (`tests.adb` main) |
| `tests.adb` | Standalone test harness |
| `Makefile` | `gnatmake -gnatwa -gnat2022 -Pk_way_merge.gpr` |
| `.gitignore` | `obj/`, `bin/`, build crumbs |

No `main.adb` — the executable is the test program under `bin/tests`.
