# Cycle Sort in Ada 2023

## Project Overview

**Cycle sort** is an **in-place**, **unstable** comparison sorting algorithm
that is theoretically **optimal in the total number of writes** to the
original array. It factors the permutation to be sorted into **cycles**,
then rotates each cycle so that every element ends in its final position.

Unlike nearly every other sort, items are never written elsewhere in the
array merely to push them out of the way. Each value is written **zero
times** if it is already correct, or **exactly once** to its correct
position. That matches the minimal number of overwrites required for a
completed in-place sort — valuable when writes are expensive (for example
EEPROM / Flash lifetime limits).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic cycle sort for `Integer` arrays.

Primary source:
[Wikipedia — Cycle sort](https://en.wikipedia.org/wiki/Cycle_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. For each cycle start index $\mathit{Cycle\_Start}$ from $A'\mathrm{First}$
   through $A'\mathrm{Last}-1$:
   - Hold $\mathit{Item} = A(\mathit{Cycle\_Start})$.
   - Find the destination $\mathit{Pos}$ by counting how many elements in
     $\mathit{Cycle\_Start}+1 \ldots A'\mathrm{Last}$ are **strictly smaller**
     than $\mathit{Item}$ (do not double-count the cycle-start slot):
     $$
     \mathit{Pos} = \mathit{Cycle\_Start}
       + \bigl|\{ i > \mathit{Cycle\_Start} : A(i) < \mathit{Item} \}\bigr|.
     $$
   - If $\mathit{Pos} = \mathit{Cycle\_Start}$, the item is already placed —
     continue.
   - Otherwise skip past equal already-placed duplicates
     ($\texttt{while Item = A(Pos) loop Pos := Pos + 1}$), write $\mathit{Item}$
     into $A(\mathit{Pos})$, and take the displaced value as the new
     $\mathit{Item}$ (one write).
   - Repeat destination-finding and writes until $\mathit{Pos}$ returns to
     $\mathit{Cycle\_Start}$, completing the cycle.
3. After the first $n-1$ cycle starts, the last element is already in place.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Example

Wikipedia's displacement cycle for the list $\{b,d,e,a,c\}$ (letters as
ordered keys): shifting the first letter $b$ to its correct position
displaces another key, which is placed next, and so on until the cycle
closes. Repeating for every cycle start yields a fully sorted array with
the fewest possible writes.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (typical) | $\Theta(n^2)$ comparisons — $O(n)$ work per cycle start |
| Time (writes) | At most $n$ writes; often far fewer when many keys are already placed |
| Auxiliary space | $O(1)$ — in-place (a few locals: held item, indices) |
| Stability | **No** — duplicate skipping can reorder equal keys |
| Write optimality | **Yes** — each element written at most once to its final slot |

Cycle sort trades many comparisons for a minimal write count. Prefer it
when writes dominate cost; prefer $O(n\log n)$ comparison sorts when CPU
time dominates.

## Features

- **`Sort (A)`** — ascending classic in-place cycle sort on `Integer`
  arrays.
- **`Sort_Counting_Writes (A)`** — same algorithm; returns the number of
  writes performed to $A$.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **Write-optimal** — each misplaced element is written once to its final
  position; already-correct elements are never overwritten.
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $10\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain; duplicates handled
  by skipping past equal already-placed positions.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcycle_sort.gpr`.

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
- Duplicate keys (multiset / runs of equals)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference (modest $n \le 500$)
- Power-of-two and odd lengths; Wikipedia-style small examples
- Idempotence (sorting twice)
- Write-count sanity (`Sort_Counting_Writes`: sorted → $0$ writes;
  reverse distinct → $n$ writes)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Cycle_Sort is
   Max_N : constant Positive := 10_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Sort_Counting_Writes (A : in out Element_Array) return Natural;
   function Is_Sorted (A : Element_Array) return Boolean;
end Cycle_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
