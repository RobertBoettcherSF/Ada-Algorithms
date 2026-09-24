# Fürer's Algorithm — Ada 2023 (educational sketch)

Educational, self-contained Ada 2023 package for **Fürer's algorithm** — the
2007 FFT-based integer multiplication that improved Schönhage–Strassen
asymptotically. Wikipedia's dedicated page
[Fürer's algorithm](https://en.wikipedia.org/wiki/F%C3%BCrer's_algorithm)
**redirects** to
[Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
(§ Further improvements); this package follows that complexity history while
shipping a **convolution / NTT teaching sketch**, not a full multi-dimensional
Fürer ring FFT and not the later Harvey–van der Hoeven galactic $O(n\log n)$
algorithm.

Non-negative integers are stored as little-endian **base-$B$ digit vectors**
($B=10^{4}$) with a modest limb cap. Below a limb threshold, `Multiply_Furer`
falls back to schoolbook. Correctness is checked against `Multiply_Schoolbook`.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Karatsuba](https://github.com/RobertBoettcherSF/Ada-Karatsuba)** — classic three-product digit-vector multiply
- **[Ada-Schonhage-Strassen](https://github.com/RobertBoettcherSF/Ada-Schonhage-Strassen)** — NTT / convolution teaching sketch (same family)
- **[Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook)** — Toom-3 digit-vector multiply
- **Booth** — upcoming
- **Multiplication algorithms** — upcoming survey
- **Montgomery** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10^{4}$ | Little-endian limbs; `Max_Operand_Limbs=32` |
| **Oracle** | `Multiply_Schoolbook` | $O(n^{2})$ limb products |
| **Fürer sketch** | `Multiply_Furer` / `Multiply_NTT` | Exact dual-prime NTT + CRT convolution |
| **Base case** | `Default_Furer_Threshold` | Schoolbook when $\max(\|A\|,\|B\|)\le T$ |
| **Ring** | Two primes $P_{1},P_{2}$ + CRT | NTT-friendly $P-1$ divisible by $64$ |
| **Invalid input** | `Invalid_Argument` | Empty / non-digit strings, `Sub` underflow, overflow |

## Brief history (redirect + complexity)

Schönhage–Strassen (1971) achieved

$$
O(n\log n\log\log n)
$$

bit complexity for $n$-bit integer multiplication via FFT over
$\mathbb{Z}/(2^{n}+1)\mathbb{Z}$. In **2007**, Martin **Fürer** proposed an
algorithm with complexity

$$
O\!\left(n\log n\, 2^{\Theta(\log^{*} n)}\right),
$$

improving the $\log\log n$ factor by using more intricate multi-dimensional
FFTs (still “almost” $O(n\log n)$ because $\log^{*}$ grows extremely slowly).
Wikipedia documents the sequel: Harvey–van der Hoeven–Lecerf (2014) made the
implicit constant explicit as $O(n\log n\, 2^{3\log^{*} n})$, improved to
$O(n\log n\, 2^{2\log^{*} n})$ in 2018; in **2019**, Harvey and van der Hoeven
proved a galactic $O(n\log n)$ bound matching the Schönhage–Strassen
conjecture (optimality remains open).

**This package is a classroom stand-in.** Full Fürer is impractical to
reproduce in a small Ada unit. We keep the *same high-level idea* as the
sibling Schönhage–Strassen teaching sketch — integer product via cyclic
convolution computed by an exact modular NTT + CRT — and document Fürer's
asymptotic place in the story. No claim that this code path realizes
$2^{O(\log^{*} n)}$ or Harvey–van der Hoeven $O(n\log n)$.

## Algorithm (educational NTT sketch)

Write each operand in base $B$ as a limb sequence (little-endian):

$$
a = \sum_{i=0}^{n-1} a_{i} B^{i},\qquad
b = \sum_{j=0}^{m-1} b_{j} B^{j}.
$$

The integer product is the **linear convolution** of $(a_{i})$ and $(b_{j})$
followed by carry propagation in base $B$. Embedding that convolution in a
cyclic convolution of length $N=2^{k}\ge n+m$ lets us use a length-$N$ DFT:

$$
c = \mathrm{IDFT}\bigl(\mathrm{DFT}(a)\odot\mathrm{DFT}(b)\bigr).
$$

**Exact modular NTT.** Choose primes $P$ with $N\mid(P-1)$ so a primitive
$N$-th root of unity exists in $\mathbb{Z}/P\mathbb{Z}$. This package uses

$$
\begin{aligned}
P_{1} &= 998244353 = 119\cdot 2^{23}+1, \\
P_{2} &= 1004535809 = 479\cdot 2^{21}+1,
\end{aligned}
$$

runs NTT multiplication modulo each $P_{\ell}$, and recovers each
non-negative convolution coefficient by CRT (product $P_{1}P_{2}$ far larger
than any coefficient for operands $\le$ `Max_Operand_Limbs`). Finally carry:

$$
c_{i} + \mathit{carry} = q\cdot B + r,\quad
\text{limb}=r,\ \mathit{carry}=q.
$$

**Relation to true Fürer.** Classical Fürer replaces “ordinary” FFT
multiplication with carefully chosen multi-dimensional transforms over rings
that reduce the $\log\log n$ overhead of Schönhage–Strassen to a
$2^{\Theta(\log^{*} n)}$ factor. The classroom code keeps the shared
convolution shape — split into digits, transform, pointwise multiply, inverse
transform, recompose — while staying exact and small. Sibling
**Ada-Schonhage-Strassen** uses the same NTT core; this package does **not**
`with` that project (reimplemented here).

**Worked size.** With $B=10^{4}$, a $48$-digit factor uses about $12$ limbs —
above `Default_Furer_Threshold` ($8$), so `Multiply_Furer` uses NTT. Tests
compare every NTT / Fürer result to the schoolbook oracle.

## API summary

| Symbol | Role |
| --- | --- |
| `Base` | Limb radix $10^{4}$ |
| `Max_Operand_Limbs` / `Max_Limbs` | Operand / product capacity |
| `Max_NTT_Length` | Power-of-two transform cap ($64$) |
| `Default_Furer_Threshold` | Schoolbook cutoff (limbs) |
| `Digit` / `Digit_Vector` | Limb type / big-int lite value |
| `Zero` / `One` | Constants $0$, $1$ |
| `From_Natural` / `From_String` | Constructors (decimal string) |
| `To_String` / `To_Natural` | Conversions |
| `Length` / `Is_Zero` / `Get_Digit` | Queries (little-endian limbs) |
| `Compare` / `Equal` | Magnitude order / equality |
| `Add` / `Sub` | Non-negative add; `Sub` requires $A\ge B$ |
| `Shift_Limbs` | Multiply by $B^{k}$ |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle |
| `Multiply_NTT` | Exact NTT + CRT convolution |
| `Multiply_Furer` | Thresholded schoolbook / NTT (+ optional `Threshold`) |
| `Invalid_Argument` | Domain / overflow errors |

## Limits and caveats

- **Educational sizes** — operands $\le$ `Max_Operand_Limbs` limbs; transform
  length $\le$ `Max_NTT_Length`.
- **Not production Fürer** — no multi-dimensional ring FFTs, no
  $2^{\Theta(\log^{*} n)}$ claim for this code path, not Harvey–van der Hoeven.
- **Non-negative only** at the public API.
- **Exact integers** — modular NTT + CRT; no floating-point FFT rounding.
- Sibling digit-vector style matches **Ada-Schonhage-Strassen** /
  **Ada-Karatsuba** / **Ada-Toom-Cook**; this package does not `with` them.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pfurer.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `furer.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
furer.ads
furer.adb
furer.gpr
tests.adb
```

Empty GitHub scaffold: https://github.com/RobertBoettcherSF/Ada-Furer
(do not push from this workspace unless explicitly requested).

## References

1. [Wikipedia: Fürer's algorithm](https://en.wikipedia.org/wiki/F%C3%BCrer's_algorithm) (redirects to Multiplication algorithm)
2. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm) — § Further improvements
3. [Wikipedia: Schönhage–Strassen algorithm](https://en.wikipedia.org/wiki/Sch%C3%B6nhage%E2%80%93Strassen_algorithm)
4. [Wikipedia: Number-theoretic transform](https://en.wikipedia.org/wiki/Discrete_Fourier_transform_(general)#Number-theoretic_transform)
5. Fürer, M. — Faster Integer Multiplication (STOC 2007)
6. Harvey, D. & van der Hoeven, J. — Integer multiplication in time $O(n\log n)$ (2019)
