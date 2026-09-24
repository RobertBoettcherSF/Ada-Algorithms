# Interpolation search (predictive search) — Ada 2023

Educational, self-contained Ada 2023 package for **interpolation search**
(also called **predictive search**): locate a key in a sorted ascending
`Integer` array by estimating the next probe with **linear interpolation**
between the current bounds, instead of always taking the midpoint as in
binary search.

Based on
[Wikipedia: Interpolation search](https://en.wikipedia.org/wiki/Interpolation_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Probe** | Linear interpolation of index | Telephone-directory style guess |
| **Alias** | Predictive search | Same algorithm; sheet synonym |
| **Average** | $O(\log\log n)$ | Uniform key distribution |
| **Worst** | $O(n)$ | e.g. exponential key growth |
| **Capacity** | `Max_N = 100_000` | `Invalid_Argument` if exceeded |
| **Miss / empty** | Sentinel `A'First - 1` | Matches sibling search packages |

## Telephone-directory analogy

People rarely open a phone book in the exact middle. If the sought name
starts with **S** and the open range runs from **A**… to **Z**…, they
open nearer the back; if the remaining pages start with **R**, they open
near the front of that span. Interpolation search does the same with
numeric keys: given bounds $L$ and $H$ with values $A(L)$ and $A(H)$,
and sought key $K$, it estimates

$$
\textit{pos} = L + \frac{(K - A(L))\cdot(H - L)}{A(H) - A(L)}
$$

(using wider integer arithmetic for the multiply so large spans do not
overflow). Compare $A(\textit{pos})$ with $K$ and shrink $[L,H]$ exactly
as in binary search. When $A(H)=A(L)$, the remaining window is an
equal-value run: return $L$ on a hit, otherwise miss.

This only makes sense when **differences of key values are meaningful**
(numeric keys on a linear scale). Names in a real directory are not
uniform on that scale; the analogy is about *guessing where to open*,
not about treating letter frequencies as integers.

## Complexity

Under the assumption that keys are **uniformly distributed** on the
interpolation scale, the expected number of probes is about
$\log\log n$. In the worst case (for example when key values grow
exponentially), the estimate can advance only one index per step and
the search costs $O(n)$ comparisons. Practical payoff is largest when
each probe is expensive (e.g. disk) and the data really are nearly
uniform; otherwise binary search’s simpler arithmetic often wins.

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

Package name: `Interpolation_Search`. Sources: `interpolation_search.ads`
/ `interpolation_search.adb`. Tests are the only main (`tests.adb`);
there is no `main.adb`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).
Artifacts go under `obj/` and `bin/`; `make test` runs `bin/tests`.

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
