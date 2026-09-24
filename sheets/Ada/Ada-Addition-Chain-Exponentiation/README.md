# Addition-Chain Exponentiation — Ada 2023

Educational, self-contained Ada 2023 package for **addition-chain
exponentiation**: represent an addition chain for the exponent, validate
it, and evaluate $b^n$ with one multiplication per chain step. See
[Addition-chain exponentiation](https://en.wikipedia.org/wiki/Addition-chain_exponentiation)
and [Addition chain](https://en.wikipedia.org/wiki/Addition_chain).

An addition chain for $n$ is a strictly increasing sequence

$$
1 = a_0 < a_1 < \cdots < a_r = n
$$

where each $a_i = a_j + a_k$ for some $k \le j < i$. Evaluating powers
along the chain uses exactly $r$ multiplications. The shortest length
$\ell(n)$ is OEIS [A003313](https://oeis.org/A003313); finding it for
arbitrary $n$ is hard (related set-version NP-complete), so this package
builds the classical **binary** (star / Brauer) chain for any $n$, and
runs an educational star-chain search for tiny $n \le 32$.

The first case where a shortest chain beats binary exponentiation is
$n = 15$: binary needs $6$ multiplications, while a shortest chain needs
only $5$:

$$
a^{15} = a \times \bigl(a \times [a \times a^{2}]^{2}\bigr)^{2}
\quad\text{(binary, 6 multiplications)}
$$

$$
a^{15} = \bigl([a^{2}]^{2} \times a\bigr)^{3}
\quad\text{(shortest, 5 multiplications)}
$$

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Exponentiating-By-Squaring](https://github.com/RobertBoettcherSF/Ada-Exponentiating-By-Squaring)** — binary / square-and-multiply powering
- **SRT division** — upcoming
- **Restoring division** — upcoming
- **Non-restoring division** — upcoming

This package does **not** `with` the sibling; a tiny binary power and
`Pow_Mod` are reimplemented here for comparison only.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Chain type** | `Chain` / `Element_Array` | $a_0,\ldots,a_r$ with `Last` $= r$ |
| **Validate** | `Is_Valid_Chain` | Start at $1$, strictly ↑, each a sum |
| **Binary chain** | `Build_Binary_Chain` | Wikipedia even/odd recurrence |
| **Shortest (tiny $n$)** | `Build_Shortest_Chain` / `Shortest_Chain_Length` | Star BFS, $n \le 32$ |
| **Evaluate** | `Evaluate_Chain` / `_Mod` | One mul per step |
| **Power API** | `Power_By_Chain` / `Power_By_Shortest_Chain` | Build then evaluate |
| **Binary mul count** | `Binary_Mul_Count` | $\lfloor\log_2 n\rfloor + \nu(n) - 1$ |
| **Comparison** | `Power_Binary` / `Pow_Mod` / `Power_Naive` | Local reimplementation |
| **Invalid input** | `Invalid_Argument` | Bad chain, $n>32$ shortest, modulus ≤1, … |

## Brief history

Addition chains appear in Knuth, *TAOCP* Vol. 2, §4.6.3. Binary
exponentiation is itself a (generally suboptimal) addition-chain method.
Brauer chains (star chains) require each sum to use the previous element;
for all $n \le 32$ (and far beyond) $\ell(n)=\ell^*(n)$. Shortest-chain
exponentiation is mainly practical for small fixed exponents that can be
precomputed.

## Algorithm

### Definition

Sequence $1 = a_0 < \cdots < a_r = n$ with $a_i = a_j + a_k$, $k \le j < i$.
Length $r$ equals the multiplication count when computing $b^{a_i}$ as
$b^{a_j} \cdot b^{a_k}$.

### Binary method chain

From Wikipedia: build a chain for $n' = \lfloor n/2 \rfloor$; if $n$ is
even append $n = n' + n'$; if odd, append after the chain for $n-1$
(using $+1$). Equivalent length:

$$
\lfloor \log_2 n \rfloor + \nu(n) - 1
$$

with $\nu(n)$ the binary Hamming weight ($\mathrm{popcount}$).

### Shortest length (educational search)

For $1 \le n \le 32$, a star-chain depth-first search with pruning against
known upper bounds fills $\ell(n)$ and one realizing chain. Results match
OEIS A003313 (e.g. $\ell(15)=5$, $\ell(31)=7$, $\ell(23)=6$).

### Evaluation

Store $p_i = b^{a_i}$. Set $p_0 = b$ (since $a_0 = 1$). For each later
index, $p_i = p_j \cdot p_k$ whenever $a_i = a_j + a_k$. Modular variants
keep intermediates in $0,\ldots,m-1$.

### Complexity note

Shortest addition-chain exponentiation never needs more multiplications
than binary, and sometimes fewer (first gap at $n=15$). Finding a globally
shortest chain for arbitrary $n$ has no known efficient algorithm; the
package therefore exposes binary construction for general $n$ and exact
shortest search only in the tiny educational range.

## API summary

| Symbol | Role |
| --- | --- |
| `Chain` / `Element_Array` | Sequence $a_0..\mathrm{Last}$ |
| `Max_Chain_Last` / `Max_Shortest_N` | Storage / search bounds ($64$ / $32$) |
| `Is_Valid_Chain` | Structural check |
| `Chain_Mul_Count` / `Chain_Exponent` | $r$ and $n$ |
| `Build_Binary_Chain` | Binary-method star chain |
| `Build_Shortest_Chain` | Shortest star chain ($n\le 32$) |
| `Binary_Mul_Count` | Binary mul count formula |
| `Shortest_Chain_Length` | $\ell(n)$ for $n\le 32$ |
| `Evaluate_Chain` / `Evaluate_Chain_Mod` | $b^n$ along a chain |
| `Power_By_Chain` / `Power_By_Chain_Mod` | Binary chain powering |
| `Power_By_Shortest_Chain` / `_Mod` | Shortest-chain powering |
| `Power_Binary` / `Pow_Mod` / `Power_Naive` | Comparison oracles |
| `Mod_Nonneg` / `Mod_Mul` | Modular helpers |
| `Invalid_Argument` | Contract / domain errors |

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022
make test   # runs bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). Zero `-gnatwa` warnings
is a project goal.

## Repository layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `addition_chain_exponentiation.ads` | Package API |
| `addition_chain_exponentiation.adb` | Implementation |
| `addition_chain_exponentiation.gpr` | GNAT project (`tests.adb` main) |
| `tests.adb` | Standalone test program |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `.gitignore` | `obj/` `bin/` |

## References

- [Addition-chain exponentiation (Wikipedia)](https://en.wikipedia.org/wiki/Addition-chain_exponentiation)
- [Addition chain (Wikipedia)](https://en.wikipedia.org/wiki/Addition_chain)
- OEIS [A003313](https://oeis.org/A003313) — length of shortest addition chain for $n$
- Donald E. Knuth, *The Art of Computer Programming*, Vol. 2, §4.6.3
