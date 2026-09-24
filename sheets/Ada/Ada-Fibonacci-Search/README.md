# Fibonacci search technique — Ada 2023

Educational, self-contained Ada 2023 package for the **Fibonacci search
technique**: locate a key in a sorted ascending `Integer` array by splitting
the search interval into unequal parts sized by consecutive Fibonacci
numbers. Probe indices are computed with addition and subtraction only — a
**division-free** alternative to classic binary search.

Based on
[Wikipedia: Fibonacci search technique](https://en.wikipedia.org/wiki/Fibonacci_search_technique).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Probe** | Offset by $F_{m-2}$ from current base | Then shrink the Fibonacci triple |
| **Setup** | Smallest $F_m \ge n$ | Keep $(F_m, F_{m-1}, F_{m-2})$ |
| **Arithmetic** | Addition / subtraction only | No division or bit-shifts needed |
| **Complexity** | $O(\log n)$ | ~4% more comparisons than binary on average |
| **Capacity** | `Max_N = 100_000` | `Invalid_Argument` if exceeded |
| **Miss / empty** | Sentinel `A'First - 1` | Matches sibling search packages |

## How it works

Fibonacci search is conceptually similar to binary search, but the cut
points follow the Fibonacci sequence rather than the midpoint. Let
$F_0 = 0$, $F_1 = 1$, and $F_k = F_{k-1} + F_{k-2}$ for $k \ge 2$. For an
array of length $n$:

1. Find the smallest Fibonacci number $F_m \ge n$. Keep the working triple
   $(\mathit{fibM}, \mathit{fibMm1}, \mathit{fibMm2}) = (F_m, F_{m-1}, F_{m-2})$.
2. Maintain an eliminated-front offset (initially $-1$ in 0-based index
   space). While $\mathit{fibM} > 1$:
   - Probe at
     $$
     i = \min(\mathit{offset} + \mathit{fibMm2},\, n - 1).
     $$
   - If $A[i] < K$, discard the left part including $i$, set
     $\mathit{offset} \leftarrow i$, and reduce the triple by **one**
     Fibonacci step:
     $$
     (\mathit{fibM}, \mathit{fibMm1}, \mathit{fibMm2})
       \leftarrow
     (\mathit{fibMm1}, \mathit{fibMm2}, \mathit{fibM} - \mathit{fibMm1}).
     $$
   - If $A[i] > K$, discard from $i$ rightward and reduce by **two** steps
     ($\mathit{fibM} \leftarrow \mathit{fibMm2}$, then rebuild the pair).
   - If $A[i] = K$, return $i$.
3. If one candidate remains ($\mathit{fibMm1} \ne 0$), compare it; otherwise
   report a miss.

Because each step only adds or subtracts Fibonacci numbers already in
registers, the algorithm historically suited machines where division or
bit-shifting was expensive. On modern CPUs the gap versus binary search is
usually negligible, but the method remains of theoretical interest and can
still help when seek cost grows with distance (e.g. magnetic tape), since
the golden-ratio split keeps the next probe relatively close after a right
elimination.

Average and worst-case comparison complexity:

$$
O(\log n).
$$

### Example

Search for $K = 85$ in the sorted array of length $n = 11$:

$$
[10, 22, 35, 40, 45, 50, 80, 82, 85, 90, 100].
$$

The smallest $F_m \ge 11$ is $F_7 = 13$, so
$(\mathit{fibM}, \mathit{fibMm1}, \mathit{fibMm2}) = (13, 8, 5)$ and
$\mathit{offset} = -1$. Probing with the $F_{m-2}$ offset yields indices
$4 \to 7 \to 9 \to 8$; the value $85$ is found at index $8$ (0-based).

## API summary

```ada
Max_N : constant Positive := 100_000;

type Element_Array is array (Natural range <>) of Integer;

Invalid_Argument : exception;

function Find (A : Element_Array; Key : Integer) return Integer;
--  Index of Key in sorted ascending A, or sentinel A'First - 1 if absent.
--  Precondition: A is sorted nondecreasing.
--  Raises Invalid_Argument if A'Length > Max_N.
--  Duplicates: any matching index is acceptable.
```

Package name: `Fibonacci_Search`. Sources: `fibonacci_search.ads` /
`fibonacci_search.adb`. Tests are the only main (`tests.adb`); there is no
`main.adb`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).
Artifacts go under `obj/` and `bin/`; `make test` runs `bin/tests` and
prints `Results: N PASS, 0 FAIL`.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
