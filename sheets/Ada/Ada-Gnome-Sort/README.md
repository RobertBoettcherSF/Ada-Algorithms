# Gnome Sort in Ada 2023

## Project Overview

**Gnome sort** (also nicknamed **stupid sort**) is a simple **comparison**
sorting algorithm originally proposed by Hamid Sarbazi-Azad in 2000 and later
described by Dick Grune. It is based on the technique used by the Dutch
garden gnome sorting flower pots: the gnome looks at the pot next to him and
the previous one; if they are in the right order he steps forward, otherwise
he swaps them and steps backward. Eventually he reaches the end of the row.

Gnome sort is **equivalent to insertion sort** in spirit, but moves each
element into place by **adjacent swaps** rather than by shifting a gap.
Average and worst-case time are $O(n^2)$; the best case on already-sorted
input is $O(n)$. Auxiliary memory is $O(1)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place** gnome sort for `Integer` arrays.

Primary source:
[Wikipedia — Gnome sort](https://en.wikipedia.org/wiki/Gnome_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Set $\mathit{pos} \leftarrow A'\mathit{First}$.
3. While $\mathit{pos} \le A'\mathit{Last}$:
   - If $\mathit{pos} = A'\mathit{First}$ **or** $A(\mathit{pos}) \ge A(\mathit{pos}-1)$,
     then $\mathit{pos} \leftarrow \mathit{pos}+1$ (step forward).
   - Else swap $A(\mathit{pos})$ with $A(\mathit{pos}-1)$ and
     $\mathit{pos} \leftarrow \mathit{pos}-1$ (fix and step back).
4. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

### Comparison choice ($>$ vs $\ge$)

Ascending order advances when $A(\mathit{pos}) \ge A(\mathit{pos}-1)$
(non-strict $\ge$). Equal keys therefore **do not** swap backward, so the
sort is **stable-ish**: equal elements keep their relative arrival order.
Using strict $>$ when deciding to advance would swap equals and lose that
property. This package prefers $\ge$ when advancing.

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{GnomeSort}(A): \\
&\quad \mathit{pos} \leftarrow A'\mathit{First} \\
&\quad \mathbf{while}\ \mathit{pos} \le A'\mathit{Last}: \\
&\quad\quad \mathbf{if}\ \mathit{pos} = A'\mathit{First}\ \mathbf{or\ else}\ A(\mathit{pos}) \ge A(\mathit{pos}-1): \\
&\quad\quad\quad \mathit{pos} \leftarrow \mathit{pos}+1 \\
&\quad\quad \mathbf{else}: \\
&\quad\quad\quad \mathrm{swap}(A(\mathit{pos}), A(\mathit{pos}-1)) \\
&\quad\quad\quad \mathit{pos} \leftarrow \mathit{pos}-1
\end{align*}
$$

### Example

Start with $\{5, 3, 1, 4, 2\}$ (`A'First` = 1):

1. $\mathit{pos}=1$ (first) $\to$ step to $2$.
2. $3 < 5$ $\to$ swap $\to$ $\{3, 5, 1, 4, 2\}$, $\mathit{pos}=1$; then step to $2$.
3. $5 \ge 3$ $\to$ step to $3$.
4. $1 < 5$ $\to$ swap $\to$ $\{3, 1, 5, 4, 2\}$, step back; continue swapping
   $1$ leftward past $3$ $\to$ $\{1, 3, 5, 4, 2\}$.
5. Continue until $\{1, 2, 3, 4, 5\}$.

Empty and singleton arrays are no-ops.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best) | $O(n)$ — already sorted (one forward pass) |
| Time (average) | $O(n^2)$ |
| Time (worst) | $O(n^2)$ — reverse sorted |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **Stable-ish** — advance on $\ge$ so equals are not swapped back |
| Relation | Insertion sort via adjacent swaps |

Gnome sort is a **comparison** sort and is **not** asymptotically optimal.
It is mainly of educational interest (and as a curiosity related to
insertion sort).

## Features

- **`Sort (A)`** — ascending in-place classic gnome (stupid) sort on
  `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Stable-ish** — equal-key order preserved by advancing on $\ge$.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $10\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pgnome_sort.gpr`.

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

(Exact `NN` is the current suite size; it is at least 70.)

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases
- Already-sorted / reverse / almost-sorted / alternating patterns
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys and **tagged stability** (key$\times 1000$ + arrival tag)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference (modest $n \le 500$)
- Power-of-two and odd lengths; gnome walk-through examples
- Idempotence (sorting twice)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$
- Reverse / random arrays kept $\le \sim 500$ because gnome sort is $O(n^2)$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Gnome_Sort is
   Max_N : constant Positive := 10_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Gnome_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
