# Ternary search — Ada 2023

Educational, self-contained Ada 2023 package for **ternary search**:
repeatedly divide a search interval into three parts. The **primary**
form here finds the index of a **maximum** in a **unimodal** discrete
`Integer` array (strictly or non-strictly increasing, then decreasing).
A **secondary** API searches for a key in a sorted ascending array with
two midpoints (binary search is usually preferable).

Based on [Wikipedia: Ternary search](https://en.wikipedia.org/wiki/Ternary_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Primary** | Unimodal peak on an array | Classic competitive-programming form |
| **Secondary** | Key in sorted ascending array | Pedagogical; prefer binary search |
| **Division** | Two thirds-points $m_1,m_2$ | Shrink by discarding one third |
| **Finish** | Linear scan on tiny window | When $H-L\le 2$ |
| **Capacity** | `Max_N = 100_000` | `Invalid_Argument` if exceeded |
| **Empty peak** | Raises `Invalid_Argument` | Peak is undefined |

## Idea

A real function $f$ on an interval is **unimodal** (for maximization) when
there is a mode $t$ such that $f$ increases up to $t$ and decreases after.
Ternary search locates the mode by evaluating $f$ at two interior points
and discarding the third of the domain that cannot contain the optimum.

On a discrete array $A(L..H)$ that is unimodal in the index domain, the
same idea applies to **indices**:

$$
m_1 = L + \left\lfloor\frac{H-L}{3}\right\rfloor,
\qquad
m_2 = H - \left\lfloor\frac{H-L}{3}\right\rfloor.
$$

Compare $A(m_1)$ and $A(m_2)$:

- if $A(m_1) < A(m_2)$, the maximum lies in $(m_1,H]$ — raise $L$;
- if $A(m_1) > A(m_2)$, the maximum lies in $[L,m_2)$ — lower $H$;
- if equal (non-strict / plateau), a maximum lies in $[m_1,m_2]$.

When the remaining window is tiny ($H-L\le 2$), finish with a linear
scan. Any index of a flat peak plateau is acceptable.

Asymptotically the unimodal peak search examines $O(\log n)$ entries
(base $3/2$ style shrinkage) plus $O(1)$ for the final window. The
sorted key-search variant is also $O(\log n)$ but typically does more
comparisons per step than binary search, so binary search is the better
default for sorted lookup.

## API summary

```ada
Max_N : constant Positive := 100_000;

type Element_Array is array (Natural range <>) of Integer;

Invalid_Argument : exception;

function Find_Maximum_Index (A : Element_Array) return Natural;
--  Index of a maximum in unimodal A.
--  Raises Invalid_Argument if A is empty or A'Length > Max_N.

function Find (A : Element_Array; Key : Integer) return Integer;
--  Index of Key in sorted ascending A, or sentinel A'First - 1 if absent.
--  Raises Invalid_Argument if A'Length > Max_N.
--  Prefer binary search in production code.
```

Package name: `Ternary_Search`. Sources: `ternary_search.ads` /
`ternary_search.adb`. Tests are the only main (`tests.adb`); there is no
`main.adb`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).
Artifacts go under `obj/` and `bin/`; `make test` runs `bin/tests`.

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
