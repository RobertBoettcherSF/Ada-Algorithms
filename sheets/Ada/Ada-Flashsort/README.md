# Flashsort in Ada 2023

## Project Overview

**Flashsort** is a **distribution** sorting algorithm published by
**Karl-Dietrich Neubert** (1998). It is an efficient **in-place**
implementation of histogram sort (a bucket sort): it assigns each of $n$
input elements to one of $m$ classes, permutes the array so those classes
occupy contiguous segments, then finishes each class with insertion sort.

For **uniformly distributed** keys the classes are balanced, each of size
about $n/m$. With $m = \Theta(n)$ that size is constant, so the final
insertion sorts cost $O(n)$ in total and the whole algorithm is

$$
O(n)
$$

expected time. Extra memory is only the $O(m)$ border vector $L$ plus a
constant number of scalars. In the **worst case** almost all items land in
a few classes and insertion sort degrades the bound to

$$
O(n^2).
$$

Flashsort is **not stable**: the in-situ permutation does not preserve the
relative order of equal keys.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic Neubert flashsort for `Integer` arrays. It does
**not** `with` sibling `Bucket_Sort` or `Counting_Sort` projects.

Primary source: [Wikipedia — Flashsort](https://en.wikipedia.org/wiki/Flashsort).

## Algorithm

Given an array $A$ of length $n$:

1. **Min / max.** Scan $A$ for $A_{\min}$ and $A_{\max}$. If they are
   equal, every key is identical and the array is already sorted (return).
   Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
   raises `Invalid_Argument`.

2. **Number of classes.** Choose

   $$
   m = \max\bigl(2,\ \lfloor n / 10 \rfloor\bigr)
   $$

   (Neubert's $m \approx 0.1\,n$, with a floor of $2$ so the interpolation
   can separate min from max). For $n \ge 2$ this is automatically $\le n$.

3. **Histogram and prefix sums.** Count how many items fall in each class
   $1..m$ into a vector $L$. Prefix-sum $L$ so $L_k$ is the inclusive
   1-based **upper border** of class $k$ (number of elements in classes
   $1..k$). Then $L_m = n$ and class $k$ occupies indices
   $L_{k-1} < i \le L_k$ (with $L_0 = 0$).

4. **Classification.** Map a key $x$ to a class by linear interpolation:

   $$
   K = 1 + \left\lfloor
     \frac{(m-1)\,(x - A_{\min})}{A_{\max} - A_{\min}}
   \right\rfloor.
   $$

   So $A_{\min} \mapsto 1$ and $A_{\max} \mapsto m$. The implementation
   uses `Long_Long_Integer` so $(m-1)(x - A_{\min})$ cannot overflow a
   32-bit `Integer` (for example $A_{\min} =$ `Integer'First` and
   $A_{\max} =$ `Integer'Last`). Truncating division of these non-negative
   quantities is $\lfloor\cdot\rfloor$.

5. **In-place permutation (cycle-following).** $L_k$ starts as the upper
   border of class $k$ and is decremented each time an item is classified
   into that class, so each class is split into an unclassified prefix and
   a classified suffix. Walk $i = 1..n$; if position $i$ is still
   unclassified, take $A_i$ as a cycle leader and repeatedly:

   - compute its class $b$;
   - swap it into slot $j = L_b$ (the next classified slot of class $b$);
   - decrement $L_b$;
   - continue with the displaced item until the cycle returns to $i$.

   Each element is moved at most once. After this pass, every class occupies
   its contiguous segment.

6. **Finish.** Insertion-sort **within each class**. Because classes are
   already in order, the concatenation is a fully sorted array.

## Why flashsort?

| Ingredient | Role |
| ---------- | ---- |
| Linear interpolation into $m$ classes | $O(n)$ classification; $m \approx 0.1 n$ |
| Histogram + prefix sums | Exact class sizes / borders in $O(m)$ words |
| Cycle-following permutation | In-place gather; no $O(n)$ output buffer |
| Per-class insertion sort | $O(1)$ per class when classes are balanced |

Bucket sort does the same scatter/sort/gather with **per-bucket lists** and
$O(n)$ extra memory. Flashsort's distinguishing step is the **in-place**
$O(n)$ permutation that uses only the $m$-word border vector. Counting sort
instead builds a count table over the *full key span* $k = A_{\max}-A_{\min}+1$,
which is the wrong tool when $k \gg n$.

Choosing $m$ trades classification work (high $m$) against insertion-sort
work (low $m$). Neubert reported that for $m = 0.1 n$ on uniform random
data, flashsort beat heapsort for all $n$ and beat quicksort for $n > 80$
(late-1990s machines; modern caches change the crossover).

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average (uniform keys, $m = \Theta(n)$) | $O(n)$ | $O(m) = O(n)$ words for $L$ |
| Worst (almost all items in a few classes) | $O(n^2)$ (insertion sort) | $O(m)$ |
| All-equal | $O(n)$ min/max scan, then return | $O(1)$ |

Unstable: equal keys may change relative order.

## Features

- **`Sort (A)`** — ascending in-place flashsort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`.
- **Class count** — $m = \max(2, \lfloor n/10 \rfloor)$ (`Class_Divisor = 10`).
- **All-equal / empty / singleton** — early exit; no division by zero.
- **Arbitrary bounds** — works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pflashsort.gpr`.

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

(Exact `NN` is the current suite size; it is at least 70.)

## Testing

The suite in `tests.adb` covers:

- Empty, singleton, and two-element arrays
- Already sorted, fully reversed, and duplicate / all-equal inputs
- Negatives and `Integer'First` / `Integer'Last` (overflow-safe class map)
- Non-1-based index bounds (0-based, 5-based, 10-based)
- Uniform-ish random arrays matched against an insertion-sort reference
- Clustered / gapped keys (unbalanced classes; still correct)
- `Is_Sorted` true/false cases
- Oversize arrays raising `Invalid_Argument`
- Idempotence of `Sort`

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Max_N` | Educational capacity bound (`100_000`) |
| `Class_Divisor` | $m = \max(2, \lfloor n/10 \rfloor)$ (`10`) |
| `Invalid_Argument` | Raised on oversize length |
| `Sort` | Ascending in-place flashsort |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Flashsort.
