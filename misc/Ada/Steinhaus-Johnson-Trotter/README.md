# Steinhaus–Johnson–Trotter in Ada 2023

## Project Overview

The **Steinhaus–Johnson–Trotter** algorithm (also called the **Johnson–Trotter**
algorithm or **plain changes**) generates all

$$
n!
$$

permutations of $n$ elements so that each two consecutive permutations differ
by swapping **two adjacent** elements. Equivalently, it traces a Hamiltonian
path on the [permutohedron](https://en.wikipedia.org/wiki/Permutohedron).

The method was known to 17th-century English change ringers; Robert Sedgewick
calls it “perhaps the most prominent permutation enumeration algorithm.”
Subsequent permutations share almost all structure, so many follow-on
computations can reuse work across adjacent swaps.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of the classic iterative **mobile-integer** formulation, with
$\mathrm{Max\_N} = 7$ ($7! = 5040$) so demos and collect-style tests stay
comfortable.

Primary source:
[Wikipedia — Steinhaus–Johnson–Trotter algorithm](https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm).

## Algorithm

Elements are the integers $1 .. n$. Each carries a **direction** (left or
right). Initially the permutation is the identity $(1\;2\;\ldots\;n)$ and
every element faces **left**.

An element is **mobile** when it is strictly larger than the neighbour it
faces (and that neighbour exists). The algorithm repeatedly:

1. Finds the **largest mobile** value $k$.
2. Swaps $k$ with the neighbour it faces (one adjacent transposition).
3. **Reverses** the direction of every value strictly larger than $k$.

It stops when no mobile element remains. The emitted sequence has length
$n!$ and each step is a plain change.

### Recursive view

The same order has a clean recursive structure: from the SJT list for
$n-1$, insert $n$ into every position of each shorter permutation, alternating
**descending** and **ascending** placement blocks. The iterative mobile-integer
procedure computes that sequence without recursion or an explicit visited set.

### Example ($n = 3$)

$$
\begin{align*}
&(1\;2\;3) \rightarrow (1\;3\;2) \rightarrow (3\;1\;2) \\
&\rightarrow (3\;2\;1) \rightarrow (2\;3\;1) \rightarrow (2\;1\;3)
\end{align*}
$$

Each arrow is a single adjacent swap.

## Complexity

| Variant | Time per permutation | Notes |
| ------- | -------------------- | ----- |
| Johnson / textbook mobile scan | $O(n)$ | Scan for largest mobile |
| Even’s direction bookkeeping | $O(1)$ average | Most steps move $n$ |
| Loopless refinements | $O(1)$ worst-case | Heavier constants |

This package uses the clear $O(n)$-per-step educational form. Generating all
permutations therefore costs $O(n \cdot n!)$ time and $O(n)$ working space
beyond the visitor’s own storage.

## Features

- **`Generate (N, Visit)`** — stream all $N!$ permutations in SJT order via
  a callback (`access procedure (P : Permutation)`).
- **`Count (N)`** / **`Factorial (N)`** — $N!$ with capacity checks.
- **`Is_Permutation`** — validates that a vector is a permutation of
  $1 .. n$.
- **`Differs_By_Adjacent_Transposition`** — detects a single plain change
  between two permutations (handy for tests and teaching).
- **Capacity guards** — `Invalid_Argument` when $N = 0$ or $N > \mathrm{Max\_N}$
  ($\mathrm{Max\_N} = 7$, $\mathrm{Max\_Count} = 5040$).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Psteinhaus_johnson_trotter.gpr`.

Elements are **$1 .. n$** (not $0 .. n-1$). Directions travel with values
when positions swap.

## API sketch

```ada
package Steinhaus_Johnson_Trotter is
   Max_N     : constant Positive := 7;
   Max_Count : constant Positive := 5_040;  -- 7!

   type Permutation is array (Positive range <>) of Positive;

   Invalid_Argument : exception;

   function Factorial (N : Natural) return Natural;
   function Count (N : Natural) return Natural;

   procedure Generate
     (N     : Natural;
      Visit : not null access procedure (P : Permutation));

   function Is_Permutation (P : Permutation) return Boolean;
   function Differs_By_Adjacent_Transposition
     (A, B : Permutation) return Boolean;
end Steinhaus_Johnson_Trotter;
```

There is **no** `main.adb`; `tests.adb` is the project main.

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

=== 1. Factorial ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

## Testing

The suite in `tests.adb` covers:

- `Factorial` / `Count` for $N = 0 .. 7$ and invalid $N$
- Exact classic order for $N = 3$
- For $N = 1 .. 5$: count $= N!$, uniqueness, every row a permutation,
  consecutive pairs differ by one adjacent transposition
- Streaming check for $N = 6$ (720 perms, adjacency, no full matrix)
- Helper predicates (`Is_Permutation`, `Differs_By_Adjacent_Transposition`)
- Identity-first property for $N = 1 .. 5`
- `Invalid_Argument` for $N = 0$ and $N > \mathrm{Max\_N}$

Aim: **40+ PASS**, **0 FAIL**.

## Project Layout

```text
ada-steinhaus-johnson-trotter/
├── .gitignore
├── Makefile
├── README.md
├── steinhaus_johnson_trotter.ads   -- package spec
├── steinhaus_johnson_trotter.adb   -- package body
├── steinhaus_johnson_trotter.gpr   -- GNAT project
└── tests.adb                       -- test main
```

## Related algorithms

- [Heap's algorithm](https://en.wikipedia.org/wiki/Heap%27s_algorithm) — another
  full permutation enumeration (not adjacent-only).
- [Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
  — random permutations, not exhaustive listing.

## License

Educational reference implementation. Algorithm credit: Hugo Steinhaus,
Selmer M. Johnson, and Hale F. Trotter; historical “plain changes” tradition
in change ringing.
