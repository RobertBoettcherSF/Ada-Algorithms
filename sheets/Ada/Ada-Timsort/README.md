# Timsort in Ada 2023

## Project Overview

**Timsort** is a hybrid, **stable** sorting algorithm derived from merge sort
and insertion sort, designed to perform well on many kinds of real-world data.
It was implemented by **Tim Peters** in 2002 for the Python programming
language. The algorithm finds subsequences of the data that are already ordered
(**natural runs**) and uses them to sort the remainder more efficiently by
merging runs until certain criteria are fulfilled.

Timsort was Python's standard sorting algorithm from version 2.3 until it was
replaced in 3.11 by **Powersort**, a derived algorithm with a more robust merge
policy. Variants have also been used in Java SE 7 (non-primitive arrays),
Android, GNU Octave, V8, and Swift.

In the worst case Timsort takes

$$
O(n \log n)
$$

comparisons. On already-sorted input it runs in linear time (adaptive). For an
input with $r$ natural runs the time is

$$
O(n \log r)
$$

This package is an **Ada 2023 (ISO/IEC 8652:2023)** **educational sketch** of
Timsort for `Integer` arrays: compute `minrun`, identify and reverse natural
runs, extend short runs with binary insertion, push onto a stack, and merge
under classic stack invariants. It is **not** identical to CPython's list sort
(see [Educational simplifications](#educational-simplifications) below).

Primary source: [Wikipedia — Timsort](https://en.wikipedia.org/wiki/Timsort).

## Algorithm

Given an array $A$ of length $n$:

1. **Minrun.** Compute a minimum run length so that $n / \mathrm{minrun}$ is
   equal to or slightly less than a power of two. Classic rule:

   $$
   \begin{align*}
   r &\leftarrow 0 \\
   \text{while } n &\ge 64: \quad r \leftarrow r \lor (n \bmod 2);\ n \leftarrow \lfloor n/2 \rfloor \\
   \mathrm{minrun} &\leftarrow n + r
   \end{align*}
   $$

   So $\mathrm{minrun} \in [32, 64]$ when $n \ge 64$, and $\mathrm{minrun} = n$
   when $n < 64$ (Timsort then reduces to binary insertion).

2. **Natural runs.** Scan left to right. A **nondecreasing** run
   ($A_i \le A_{i+1}$) is kept as-is. A **strictly descending** run
   ($A_i > A_{i+1}$) is **reversed in place** (strict inequality excludes
   equals so reversing stays stable). If the run is shorter than
   $\mathrm{minrun}$, extend it with **binary insertion sort**.

3. **Stack merges.** Push each finished run onto a stack. After each push,
   enforce classic Timsort invariants on the top three runs $X$ (newest),
   $Y$, $Z$ (older):

   - while $\ge 3$ runs and $|Z| \le |Y| + |X|$: merge $Y$ with the smaller
     of $X$ and $Z$ (prefer $Z{+}Y$ when $|Z| < |X|$, else $Y{+}X$);
   - else while $\ge 2$ runs and $|Y| \le |X|$: merge $Y{+}X$.

   After the scan, collapse the stack by merging until one run remains.

4. **Stable merge.** Adjacent runs are merged through a temporary buffer of
   size $n$; when keys compare equal, prefer the **left** run so relative
   order is preserved.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

## Educational simplifications

This sketch intentionally differs from full CPython Timsort:

| Feature | This package | Full CPython / OpenJDK Timsort |
| ------- | ------------ | ------------------------------ |
| Galloping mode | **Skipped** | Exponential + binary search when one run wins repeatedly |
| Merge buffer | Full $n$ temp | Often copies only the smaller shrunk run |
| Merge policy | Classic $|Z| \le |Y|{+}|X|$ / $|Y| \le |X|$ | Later Powersort / power-law refinements |
| Helpers | Inlined | Separate insertion / merge modules |

Galloping and shrunk-run merge tricks improve constants on patterned data but
complicate an educational reading. Correctness, stability, and the
$\Theta(n \log n)$ / near-linear-on-sorted asymptotics are preserved.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (worst) | $\Theta(n \log n)$ |
| Time (best / already sorted) | $\Theta(n)$ |
| Time ($r$ natural runs) | $O(n \log r)$ |
| Auxiliary space | $\Theta(n)$ temp buffer + $O(1)$ run stack (bounded) |
| Stability | **Yes** — left-preferring merge; strict descending reverses |

## Features

- **`Sort (A)`** — ascending educational Timsort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Stable hybrid** — natural runs + binary insertion + stack merges.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptimsort.gpr`.

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
- Nearly-sorted inputs and few-run block patterns (Timsort's sweet spot)
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys and **tagged stability** (key×1000 + arrival tag)
- Non-1 `A'First` index bounds
- Random arrays vs a stable insertion-sort reference
- Power-of-two, odd, and near-minrun lengths ($n = 63, 64, 65, \ldots$)
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
package Timsort is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Timsort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
