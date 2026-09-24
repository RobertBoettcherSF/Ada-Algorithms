# Jump search (block search) — Ada 2023

Educational, self-contained Ada 2023 package for **jump search** (also
called **block search**): locate a key in a sorted ascending `Integer`
array by jumping ahead in fixed-size blocks of length
$m = \lfloor\sqrt{n}\rfloor$ (or an explicit `Step`), then finishing with a
short linear scan of the block that may contain the key.

Based on
[Wikipedia: Jump search](https://en.wikipedia.org/wiki/Jump_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Probe** | Fixed jumps of size $m$ | Then linear scan one block |
| **Alias** | Block search | Same algorithm; sheet synonym |
| **Optimal $m$** | $m = \lfloor\sqrt{n}\rfloor$ | Balances jump vs linear phase |
| **Complexity** | $O(\sqrt{n})$ | Better than linear, worse than binary |
| **Capacity** | `Max_N = 100_000` | `Invalid_Argument` if exceeded |
| **Step = 0** | `Invalid_Argument` | Explicit-Step overload only |
| **Miss / empty** | Sentinel `A'First - 1` | Matches sibling search packages |

## How it works

Jump search trades a little asymptotic speed for a **single backward jump**.
With block size $m$ and length $n$:

1. Start at the beginning. Jump forward by $m$ indices while the element
   at the end of the current block is strictly less than the key $K$.
2. When a block is found whose last element is $\ge K$ (or the end of the
   array is reached), **linearly scan** that block from its start.

Wikipedia / NIST formulation (0-based list $L$ of length $n$, key $s$):

$$
a \leftarrow 0,\quad b \leftarrow \lfloor\sqrt{n}\rfloor
$$

while $L_{\min(b,n)-1} < s$, set $a \leftarrow b$, $b \leftarrow b + \lfloor\sqrt{n}\rfloor$;
if $a \ge n$, miss. Then scan $a, a+1, \ldots$ until $L_a \ge s$ or the
block ends; hit if $L_a = s$.

Both phases examine at most about $\sqrt{n}$ elements when
$m = \lfloor\sqrt{n}\rfloor$, so the total cost is

$$
O(\sqrt{n}).
$$

That is better than plain linear search ($O(n)$) but worse than binary
search ($O(\log n)$). The practical niche is when **jumping backward is
expensive** compared with jumping forward (e.g. some tape / linked /
streaming settings): binary search may retreat up to $\log n$ times,
while jump search retreats once.

An optional overload accepts an explicit `Step` so you can experiment with
other block sizes (or multi-level jump ideas from the literature).

## API summary

```ada
Max_N : constant Positive := 100_000;

type Element_Array is array (Natural range <>) of Integer;

Invalid_Argument : exception;

function Find (A : Element_Array; Key : Integer) return Integer;
--  Index of Key in sorted ascending A, or sentinel A'First - 1 if absent.
--  Block size m = floor(sqrt(A'Length)) when A is non-empty.
--  Precondition: A is sorted nondecreasing.
--  Raises Invalid_Argument if A'Length > Max_N.
--  Duplicates: any matching index is acceptable.

function Find
  (A    : Element_Array;
   Key  : Integer;
   Step : Natural) return Integer;
--  Same as Find, but uses Step as the jump / block size.
--  Raises Invalid_Argument if A'Length > Max_N or Step = 0.
```

Package name: `Jump_Search`. Sources: `jump_search.ads` /
`jump_search.adb`. Tests are the only main (`tests.adb`); there is no
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
