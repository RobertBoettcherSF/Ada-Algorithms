# Brute-Force Search (Exhaustive / Generate-and-Test) in Ada 2023

## Project Overview

**Brute-force search** (also called **exhaustive search** or **generate and
test**) is a general problem-solving paradigm: systematically produce every
candidate solution and test whether it satisfies the problem statement.
It is simple, always correct when a solution exists in the enumerated
space, and often the right baseline — but the candidate count grows steeply
with problem size (**combinatorial explosion**).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational kit of four
concrete demos of that loop:

| Demo | Candidates | Educational bound |
| --- | --- | --- |
| **Trial division** (`Find_Divisor`) | $2..N$ | none (input is `Positive`) |
| **Linear search** (`Linear_Search`) | list indices | $n \le \mathrm{Max\_Linear\_N}=10^5$ |
| **Subset sum** (`Subset_Sum_Exists`) | $2^n$ bit masks | $n \le \mathrm{Max\_Subset\_N}=20$ |
| **Permutations** (`Count_Permutations` / `Find_Permutation`) | $n!$ | $n \le \mathrm{Max\_Perm\_N}=8$ |

Primary source:
[Wikipedia — Brute-force search](https://en.wikipedia.org/wiki/Brute-force_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Brute-Force-Search`) | Full generate-and-test; no pruning |
| **[Ada-Linear-Search](https://github.com/RobertBoettcherSF/Ada-Linear-Search)** | Dedicated sequential list scan |
| **[Ada-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Binary-Search)** | Logarithmic search on sorted data |
| Backtracking (sibling when published) | Discard whole regions without listing them |

README links only — **no** package `with` of siblings. Brute force must
**not** be confused with backtracking (Wikipedia).

## Generate-and-test skeleton

Wikipedia expresses the method with four procedures over instance data $P$:

- $\mathrm{first}(P)$ — first candidate (or $\Lambda$ if none)
- $\mathrm{next}(P,c)$ — next candidate after $c$ (or $\Lambda$ when done)
- $\mathrm{valid}(P,c)$ — whether $c$ solves $P$
- $\mathrm{output}(P,c)$ — use a solution

$$
\begin{align*}
&c \leftarrow \mathrm{first}(P) \\
&\mathbf{while}\ c \neq \Lambda\ \mathbf{do} \\
&\quad \mathbf{if}\ \mathrm{valid}(P,c):\ \mathrm{output}(P,c) \\
&\quad c \leftarrow \mathrm{next}(P,c) \\
&\mathbf{end\ while}
\end{align*}
$$

Each API below specialises that loop (often stopping at the first hit).

## Algorithms

### 1. Trial division — `Find_Divisor`

Instance $P = N$. Candidates are $c = 2,3,\ldots,N$. A candidate is valid
when $N \bmod c = 0$. The **smallest** valid $c$ is returned. For primes
(and for $N=1$) the search falls through to $c=N$, so the result is $N$.

$$
\mathrm{Find\_Divisor}(N)=\min\{c\in\{2,\ldots,N\} : N \bmod c = 0\}
\quad (N\ge 2),\qquad
\mathrm{Find\_Divisor}(1)=1.
$$

**Vs smarter methods:** trial only up to $\sqrt{N}$ is enough for
factorisation; Pollard's rho / ECM / sieves scale far better for large $N$.
This routine deliberately walks the full $2..N$ educational space.

### 2. Linear search — `Linear_Search`

Candidates are indices $i \in A'\mathit{First}..A'\mathit{Last}$. Valid when
$A(i)=\mathit{Key}$. Returns the first hit, or the sentinel
$A'\mathit{First}-1$ if none (Wikipedia: the table-scan form of brute force
*is* linear search).

$$
\begin{align*}
&\mathbf{for}\ i \leftarrow A'\mathit{First}\ \mathbf{to}\ A'\mathit{Last}: \\
&\quad \mathbf{if}\ A(i)=\mathit{Key}:\ \mathbf{return}\ i \\
&\mathbf{return}\ A'\mathit{First}-1
\end{align*}
$$

Raises `Invalid_Argument` when $n > \mathrm{Max\_Linear\_N}$.

### 3. Subset sum — `Subset_Sum_Exists`

Candidates are all subsets of an $n$-element array, encoded as masks
$m \in \{0,\ldots,2^n-1\}$. Valid when the masked sum equals $\mathit{Target}$.
The empty subset (mask $0$) sums to $0$.

$$
\exists S \subseteq \{0,\ldots,n-1\}:\quad
\sum_{i\in S} A(A'\mathit{First}+i) = \mathit{Target}.
$$

Raises `Invalid_Argument` when $n > \mathrm{Max\_Subset\_N}$.

**Vs smarter methods:** meet-in-the-middle $O(2^{n/2})$, pseudo-polynomial DP
$O(n\cdot \Sigma |a_i|)$, or ILP / branch-and-bound with pruning.

### 4. Permutations — password-style exhaustive

Candidates are the $n!$ permutations of $\{1,\ldots,n\}$ in lexicographic
order (educational stand-in for short password / key enumeration).

- `Count_Permutations(N)` / `Enumerate_Permutations` — generate every
  permutation and return how many were produced ($= N!$; $0!=1$).
- `Find_Permutation(Target)` — 1-based lex rank of `Target`, or $0$ if
  `Target` is not a permutation of $1..n$ ($n=\mathit{Target}'\mathit{Length}$).

Raises `Invalid_Argument` when $n > \mathrm{Max\_Perm\_N}$.

**Vs smarter methods:** do not brute-force real passwords or crypto keys;
use proper KDF/auth protocols. Combinatorial search with pruning
(backtracking, dancing links, SAT) beats raw $n!$ whenever structure exists.

### Combinatorial explosion (why bounds exist)

| Growth | Example | Scale |
| --- | --- | --- |
| Linear $\Theta(N)$ | trial division of $N$ | fine for demos |
| Exponential $2^n$ | subset sum | $2^{20}\approx 10^6$ masks |
| Factorial $n!$ | permutations | $8!=40320$, $20!\approx 2.4\times 10^{18}$ |

Wikipedia's letter-rearrangement example: $10!$ is easy on a PC; $20!$ is
on the order of years. Educational caps keep demos honest.

## Complexity

| Routine | Time | Extra space |
| --- | --- | --- |
| `Find_Divisor` | $\Theta(d)$ ($d$ = result; $\Theta(N)$ worst) | $O(1)$ |
| `Linear_Search` | $O(n)$ worst / average; $O(1)$ best | $O(1)$ |
| `Subset_Sum_Exists` | $\Theta(2^n\cdot n)$ | $O(1)$ |
| `Count_Permutations` | $\Theta(n\cdot n!)$ | $O(n)$ |
| `Find_Permutation` | $O(n\cdot n!)$ (early exit on hit) | $O(n)$ |

## Features

- Four generate-and-test demos in one package (`Brute_Force_Search`).
- Clear educational caps with `Invalid_Argument` on oversized inputs.
- Arbitrary `Natural` array bounds for list / subset / permutation APIs.
- Empty-array and $N=1$ / $n=0$ edge cases defined.
- Zero-warning build: `gnatmake -gnatwa -gnat2022 -Pbrute_force_search.gpr`.

## Usage

```ada
with Brute_Force_Search; use Brute_Force_Search;

procedure Demo is
   A      : constant Element_Array := [3, 1, 4, 1, 5];
   Target : constant Element_Array := [2, 1, 3];
   Count  : Natural;
begin
   --  Trial division: 91 = 7 * 13 → smallest divisor 7
   pragma Assert (Find_Divisor (91) = 7);
   pragma Assert (Find_Divisor (17) = 17);  -- prime → N

   --  Linear search
   pragma Assert (Linear_Search (A, 4) = 2);  -- 0-based example

   --  Subset sum: {3,1,4} contains a subset summing to 5 (1+4)
   pragma Assert (Subset_Sum_Exists (A (0 .. 2), 5));

   --  Permutations of 1..3
   pragma Assert (Count_Permutations (3) = 6);
   Enumerate_Permutations (3, Count);
   pragma Assert (Count = 6);
   pragma Assert (Find_Permutation (Target) = 3);  -- 1,2,3 / 1,3,2 / 2,1,3
end Demo;
```

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pbrute_force_search.gpr
make test     # run bin/tests — expect all PASS
make clean
```

## API summary

| Symbol | Role |
| --- | --- |
| `Find_Divisor(N)` | Smallest divisor in $2..N$, or $N$ if prime / $N=1$ |
| `Linear_Search(A,Key)` | First index of `Key`, else $A'\mathit{First}-1$ |
| `Subset_Sum_Exists(A,Target)` | Whether any subset sums to `Target` |
| `Count_Permutations(N)` | Exhaustive count of $N!$ permutations |
| `Enumerate_Permutations(N,Count)` | Procedure form of the count |
| `Find_Permutation(Target)` | 1-based lex rank, or $0$ if invalid |
| `Invalid_Argument` | Oversized $n$ relative to educational caps |
| `Max_Linear_N` / `Max_Subset_N` / `Max_Perm_N` | Capacity constants |

## References

1. Wikipedia contributors, “Brute-force search,”
   https://en.wikipedia.org/wiki/Brute-force_search
2. Wikipedia, “Linear search,” “Subset sum problem,” “Brute-force attack”
3. Ada 2023 (ISO/IEC 8652:2023) — GNAT `-gnat2022`
