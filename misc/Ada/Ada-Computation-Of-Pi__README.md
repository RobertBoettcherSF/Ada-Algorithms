# Computing π — Ada 2023 survey

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Computing π](https://en.wikipedia.org/wiki/Computing_%CF%80).
Classroom `Long_Float` sketches of contrasting methods (slow series,
Machin-like arctan formulae, Archimedes polygons, and tiny BBP / AGM /
Chudnovsky demos). This package does **not** `with` sibling repos; it
implements lightweight sketches and points to full packages for depth.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (full implementations — use those, not this survey body):

- **[Ada-Spigot-Algorithm](https://github.com/RobertBoettcherSF/Ada-Spigot-Algorithm)** — digit-by-digit $e$ / $\pi$ spigots
- **[Ada-Gauss-Legendre](https://github.com/RobertBoettcherSF/Ada-Gauss-Legendre)** — Brent–Salamin / AGM iteration for $\pi$
- **[Ada-Chudnovsky](https://github.com/RobertBoettcherSF/Ada-Chudnovsky)** — Ramanujan–Sato series for $1/\pi$ (~14 digits / term)
- **[Ada-Borwein](https://github.com/RobertBoettcherSF/Ada-Borwein)** — quartic AGM-style iteration for $1/\pi$
- **[Ada-BBP](https://github.com/RobertBoettcherSF/Ada-BBP)** — Bailey–Borwein–Plouffe series + hex-digit sketch
- **[Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)** — recursive integer $(P,Q)$ products (production Chudnovsky)

Upcoming (numerical DE / ODE educational track — **Verlet skipped**,
Ada slot is [Ada-Velvet](https://github.com/RobertBoettcherSF/Ada-Velvet)):
Trapezoidal DE, Euler, RK.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Survey API** | `Method` enum + `Approximate_Pi` | Dispatcher over sketches |
| **Slow series** | Leibniz, Nilakantha | $O(1/n)$ / $O(1/n^3)$ style |
| **Arctan** | Machin + `Arctan_Series` | $\pi/4=4\arctan\frac15-\arctan\frac1{239}$ |
| **Polygons** | Archimedes doubling | Inscribed hex → $6\cdot 2^n$ sides |
| **Fast demos** | Tiny BBP / AGM / Chudnovsky | Catalogue only; see siblings |
| **Reference** | `Pi_Constant`, `Ada_Pi`, `Elementary_Pi` | Literals + `Ada.Numerics` + $4\arctan 1$ |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Effort $0$ or $>\mathrm{Max\_Effort}$ |
| **Cap** | $\mathrm{Effort}\le 10000$ | `Max_Effort` |

## Slow vs fast taxonomy

Wikipedia’s “Computing $\pi$” page groups methods by convergence and
purpose. This survey mirrors that taxonomy in `Long_Float`:

| Class | Methods here | Typical behaviour |
| --- | --- | --- |
| **Slow infinite series** | Leibniz, Nilakantha | Many terms for a few digits |
| **Machin-like arctan** | Machin | Far fewer terms than Leibniz |
| **Geometric / polygons** | Archimedes | Digits grow with doublings |
| **Digit extraction** | BBP partial sum (sketch) | Full hex spigot → **Ada-BBP** |
| **Quadratic AGM** | AGM (few steps) | Digit-doubling → **Ada-Gauss-Legendre** |
| **Hypergeometric / Ramanujan–Sato** | Chudnovsky one–few terms | ~14 digits/term → **Ada-Chudnovsky** |
| **Higher-order AGM** | (pointer only) | Quartic → **Ada-Borwein** |
| **Spigots** | (pointer only) | Digit-by-digit → **Ada-Spigot-Algorithm** |

Do **not** treat the BBP / AGM / Chudnovsky sketches here as replacements
for the sibling packages (no full digit extraction, no multiprecision,
no binary splitting).

## Algorithms (this package)

### 1. Leibniz

$$
\frac{\pi}{4}=\sum_{k=0}^{\infty}\frac{(-1)^k}{2k+1}.
$$

`Leibniz_Pi(Terms)` returns $4$ times the partial sum of the first
$\mathrm{Terms}$ summands. Convergence is slow ($\sim 1/n$).

### 2. Nilakantha

$$
\pi=3+\sum_{k=1}^{\infty}(-1)^{k+1}\frac{4}{(2k)(2k+1)(2k+2)}.
$$

Faster than Leibniz for the same term count, still polynomial-rate.

### 3. Machin (arctan series)

Machin’s formula:

$$
\frac{\pi}{4}=4\arctan\frac{1}{5}-\arctan\frac{1}{239}.
$$

With the Taylor sketch

$$
\arctan x=\sum_{k=0}^{\infty}(-1)^k\frac{x^{2k+1}}{2k+1},
$$

`Machin_Pi(Terms)` evaluates both arctangents with `Arctan_Series`. For
the same effort, absolute error is typically many orders of magnitude
smaller than Leibniz.

### 4. Archimedes (polygon doubling)

Start with a unit-circle inscribed regular hexagon (side length $1$).
Each doubling uses the chord recurrence

$$
s_{2n}=\sqrt{2-\sqrt{4-s_n^2}},
$$

then $\pi\approx (n\cdot s_n)/2$. Educational bound sketch only.

### 5. Tiny BBP partial sum

$$
\pi=\sum_{k=0}^{\infty}16^{-k}\Bigl(\frac{4}{8k+1}-\frac{2}{8k+4}-\frac{1}{8k+5}-\frac{1}{8k+6}\Bigr).
$$

`BBP_Partial_Pi` sums the first $\mathrm{Terms}$ terms. For hex-digit
extraction and a fuller API, see **Ada-BBP**.

### 6. Light AGM (Gauss–Legendre / Brent–Salamin)

$$
\begin{aligned}
a_0&=1,\quad b_0=\tfrac{1}{\sqrt{2}},\quad t_0=\tfrac14,\quad p_0=1,\\
a_{n+1}&=\tfrac{a_n+b_n}{2},\quad
b_{n+1}=\sqrt{a_n b_n},\\
t_{n+1}&=t_n-p_n(a_n-a_{n+1})^2,\quad
p_{n+1}=2p_n,\\
\pi&\approx\frac{(a_n+b_n)^2}{4t_n}.
\end{aligned}
$$

`AGM_Pi` runs a few iterations as a catalogue demo. Full package:
**Ada-Gauss-Legendre**.

### 7. Chudnovsky (one–few terms)

Catalogue form with $A=13591409$, $B=545140134$, $C=640320$:

$$
t_k=\frac{(-1)^k(6k)!(A+Bk)}{(3k)!(k!)^3 C^{3k}},\qquad
S_N=\sum_{k=0}^{N-1}t_k,\qquad
\pi\approx\frac{426880\sqrt{10005}}{S_N}.
$$

Implemented via a term-ratio recurrence (no standalone $(6k)!$). Full
series + binary splitting: **Ada-Chudnovsky**, **Ada-Binary-Splitting**.

### Dispatcher

```ada
type Method is
  (Leibniz, Nilakantha, Machin, Archimedes,
   BBP_Partial, AGM, Chudnovsky_Term);

function Approximate_Pi
  (Which  : Method;
   Effort : Effort_Count := Default_Effort) return Long_Float;

procedure Approximate_Pi
  (Which    :     Method;
   Effort   :     Effort_Count := Default_Effort;
   Estimate : out Long_Float;
   Abs_Err  : out Long_Float);  -- vs Pi_Constant
```

`Effort` means terms, doublings, or AGM iterations depending on `Method`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcomputation_of_pi.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Exactly seven root files: `.gitignore`, `Makefile`, `README.md`,
`computation_of_pi.ads`, `computation_of_pi.adb`, `computation_of_pi.gpr`,
`tests.adb` (no `main.adb`).

## API summary

| Symbol | Role |
| --- | --- |
| `Method` | Catalogue enum (7 sketches) |
| `Effort_Count` / `Max_Effort` / `Default_Effort` | Shared effort domain |
| `Pi_Constant` / `Ada_Pi` / `Elementary_Pi` | Reference $\pi$ |
| `Near` / `Abs_Error` / `Rel_Error` | Comparison helpers |
| `Leibniz_Pi` / `Nilakantha_Pi` / `Machin_Pi` | Series sketches |
| `Arctan_Series` | Shared Taylor building block |
| `Archimedes_Pi` | Polygon doubling sketch |
| `BBP_Partial_Pi` / `AGM_Pi` / `Chudnovsky_Pi` | Fast-method demos |
| `Approximate_Pi` | Function + procedure dispatcher |
| `Invalid_Argument` | Domain errors |

## Licence

Educational use; see repository licence if present.
