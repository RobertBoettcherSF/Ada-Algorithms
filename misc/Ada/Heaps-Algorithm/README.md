# Heap's Algorithm in Ada 2023

## Project Overview

**Heap's algorithm** generates all

$$
n!
$$

permutations of $n$ objects. It was first proposed by **B. R. Heap** in 1963.
The method minimizes movement: each permutation is produced from the previous
one by a **single transposition** (swap of two elements — **not** necessarily
adjacent).

> **Not heapsort.** Despite the similar name, this package implements B. R.
> Heap's *permutation-generation* algorithm. It has nothing to do with the
> heap data structure or heapsort.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of the classic **recursive** formulation, with $\mathrm{Max\_N} = 7$
($7! = 5040$) so demos and collect-style tests stay comfortable.

Primary source:
[Wikipedia — Heap's algorithm](https://en.wikipedia.org/wiki/Heap%27s_algorithm).

## Algorithm

Elements are the integers $1 .. n$. Start from the identity permutation
$(1\;2\;\ldots\;n)$. The recursive procedure on a prefix of length $k$ is:

$$
\begin{align*}
&\textbf{if } k = 1 \textbf{ then} \\
&\quad \text{visit } A \\
&\textbf{else} \\
&\quad \text{Generate}(k-1) \\
&\quad \textbf{for } i = 1 .. k-1 \textbf{ do} \\
&\quad\quad \textbf{if } k \text{ is even then swap } A(i), A(k) \\
&\quad\quad \textbf{else swap } A(1), A(k) \\
&\quad\quad \text{Generate}(k-1) \\
&\quad \textbf{end for} \\
&\textbf{end if}
\end{align*}
$$

After each block of $(k-1)!$ permutations, a single swap brings a new
arrangement of the first $k$ positions. The emitted sequence has length $n!$.

### Example ($n = 3$)

$$
\begin{align*}
&(1\;2\;3) \rightarrow (2\;1\;3) \rightarrow (3\;1\;2) \\
&\rightarrow (1\;3\;2) \rightarrow (2\;3\;1) \rightarrow (3\;2\;1)
\end{align*}
$$

Each arrow is a single swap (some adjacent, some not — e.g. $(2\;1\;3)$ to
$(3\;1\;2)$ swaps positions $1$ and $3$).

## Complexity

| Aspect | Cost | Notes |
| ------ | ---- | ----- |
| Time per permutation | $O(1)$ amortized | One swap + visit |
| Full enumeration | $O(n!)$ swaps | Plus visitor work |
| Working space | $O(n)$ | Array + recursion depth $n$ |

Generating all permutations therefore costs $O(n!)$ swaps and $O(n)$ stack
space beyond the visitor’s own storage. Compared with
[Steinhaus–Johnson–Trotter](https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm),
Heap’s swaps need not be adjacent, which can be slightly cheaper to compute
but less useful when follow-on work benefits from locality.

## Features

- **`Generate (N, Visit)`** — stream all $N!$ permutations in Heap order via
  a callback (`access procedure (P : Permutation)`).
- **`Count (N)`** / **`Factorial (N)`** — $N!$ with capacity checks.
- **`Is_Permutation`** — validates that a vector is a permutation of
  $1 .. n$.
- **`Differs_By_Single_Swap`** — detects a single transposition (any two
  positions) between two permutations (handy for tests and teaching).
- **Capacity guards** — `Invalid_Argument` when $N = 0$ or $N > \mathrm{Max\_N}$
  ($\mathrm{Max\_N} = 7$, $\mathrm{Max\_Count} = 5040$).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pheaps_algorithm.gpr`.

Elements are **$1 .. n$** (not $0 .. n-1$).

## API sketch

```ada
package Heaps_Algorithm is
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
   function Differs_By_Single_Swap
     (A, B : Permutation) return Boolean;
end Heaps_Algorithm;
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
- Exact classic Heap order for $N = 3$
- For $N = 1 .. 5$: count $= N!$, uniqueness, every row a permutation,
  consecutive pairs differ by one (possibly non-adjacent) swap
- Streaming check for $N = 6$ (720 perms, single-swap chain, no full matrix)
- Helper predicates (`Is_Permutation`, `Differs_By_Single_Swap`)
- Identity-first property for $N = 1 .. 6$
- `Invalid_Argument` for $N = 0$ and $N > \mathrm{Max\_N}$
- Streaming `Generate(Max_N)` yields $5040$ permutations

Aim: **40+ PASS**, **0 FAIL**.

## Project Layout

```text
ada-heaps-algorithm/
├── .gitignore
├── Makefile
├── README.md
├── heaps_algorithm.ads   -- package spec
├── heaps_algorithm.adb   -- package body (recursive Heap)
├── heaps_algorithm.gpr   -- GNAT project
└── tests.adb             -- test main
```

## Related algorithms

- [Steinhaus–Johnson–Trotter](https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm)
  — full permutation enumeration with **adjacent** swaps only.
- [Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
  — random permutations, not exhaustive listing.
- [Heapsort](https://en.wikipedia.org/wiki/Heapsort) — unrelated sorting
  algorithm that uses a binary heap (different “Heap”).

## License

Educational reference implementation. Algorithm credit: B. R. Heap (1963),
“Permutations by Interchanges,” *The Computer Journal* 6(3):293–298.
