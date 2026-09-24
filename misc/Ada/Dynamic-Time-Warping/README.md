# Dynamic Time Warping in Ada 2023

## Project Overview

**Dynamic Time Warping (DTW)** measures similarity between two temporal
sequences that may vary in speed. It finds an **optimal monotonic
alignment** that minimises the cumulative local distance under continuity
constraints — allowing one series to “stretch” or “compress” in time
relative to the other.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of **classic DTW** for integer sequences, with local cost
$d(x,y)=|x-y|$, a fixed DP pool sized to `Max_Len`, and an optional
**Sakoe–Chiba band** window.

Primary source:
[Wikipedia — Dynamic time warping](https://en.wikipedia.org/wiki/Dynamic_time_warping).

## Algorithm

Given series $X = x_1\ldots x_m$ and $Y = y_1\ldots y_n$, define the
local cost

$$
d(x_i, y_j) = |x_i - y_j|
$$

and the DTW table

$$
\begin{aligned}
\mathrm{DTW}(1,1) &= d(x_1,y_1) \\
\mathrm{DTW}(1,j) &= d(x_1,y_j) + \mathrm{DTW}(1,j-1) \\
\mathrm{DTW}(i,1) &= d(x_i,y_1) + \mathrm{DTW}(i-1,1) \\
\mathrm{DTW}(i,j) &= d(x_i,y_j) + \min\bigl(
  \mathrm{DTW}(i-1,j),\;
  \mathrm{DTW}(i,j-1),\;
  \mathrm{DTW}(i-1,j-1)
\bigr)
\end{aligned}
$$

The distance returned is $\mathrm{DTW}(m,n)$ — the cost of an optimal
warping path from $(1,1)$ to $(m,n)$.

Equivalently (0-based sentinel form often seen in literature):

$$
\mathrm{DTW}(0,0)=0,\quad
\mathrm{DTW}(i,0)=\mathrm{DTW}(0,j)=\infty\ (i,j>0)
$$

then $\mathrm{DTW}(i,j)=d(x_i,y_j)+\min(\ldots)$ for $i,j\ge 1$.

### Example (hand computation)

$X=(1,3)$, $Y=(1,2,3)$:

| $d$ | $1$ | $2$ | $3$ |
| --- | --- | --- | --- |
| $1$ | $0$ | $1$ | $2$ |
| $3$ | $2$ | $1$ | $0$ |

| DTW | $1$ | $2$ | $3$ |
| --- | --- | --- | --- |
| $1$ | $0$ | $1$ | $3$ |
| $3$ | $2$ | $1$ | $1$ |

So $\mathrm{Distance}(X,Y)=1$. Identical series always yield $0$.

### Sakoe–Chiba band (optional)

A window $w$ restricts cell $(i,j)$ to $|i-j|\le w$. This reduces work
and forbids extreme warps. Feasibility requires

$$
w \ge |m - n|
$$

otherwise `Invalid_Argument` is raised. A window at least
$\max(m,n)$ recovers unconstrained DTW.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (classic) | $O(mn)$ |
| Time (band $w$) | $O(n\cdot w)$ typical |
| Space | $O(mn)$ fixed pool sized to `Max_Len` |
| Capacity | Each series length $\le \mathrm{Max\_Len}$ (default $256$) |

## Features

- **`type Series`** — `array (Positive range <>) of Integer`
- **`Distance (X, Y)`** — classic unconstrained DTW path cost (`Natural`)
- **`Distance (X, Y, Window)`** — Sakoe–Chiba banded DTW
- **`Local_Cost (A, B)`** — $|A-B|$ without `abs` overflow on `Integer'First`
- **`Invalid_Argument`** — empty series, length $>$ `Max_Len`, or band too narrow
- **Arbitrary `Positive` bounds** — `X'First` / `Y'First` need not be $1$
- **Symmetric** — $\mathrm{Distance}(X,Y)=\mathrm{Distance}(Y,X)$
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdynamic_time_warping.gpr`

## Empty / capacity policy

| Case | Behaviour |
| ---- | --------- |
| Either series empty | `Invalid_Argument` |
| Length $>$ `Max_Len` | `Invalid_Argument` |
| Band $w < \|m-n\|$ | `Invalid_Argument` |

(Empty $\to 0$ is *not* used here; empty inputs are rejected so callers
must supply nonempty series.)

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Remove obj/ and bin/
make clean
```

```ada
with Dynamic_Time_Warping; use Dynamic_Time_Warping;

declare
   X : constant Series := (1, 2, 3, 4);
   Y : constant Series := (1, 2, 2, 3, 4);
   D : Natural;
begin
   D := Distance (X, Y);           -- classic
   D := Distance (X, Y, Window => 2);  -- Sakoe–Chiba
end;
```

## API summary

| Entity | Role |
| ------ | ---- |
| `Max_Len` | Capacity constant ($256$) |
| `Series` | Integer sample array |
| `Distance (X, Y)` | Classic DTW cost |
| `Distance (X, Y, Window)` | Banded DTW cost |
| `Local_Cost` | Absolute local cost |
| `Invalid_Argument` | Empty / oversize / infeasible band |

## Project layout

| File | Role |
| ---- | ---- |
| `dynamic_time_warping.ads` | Package specification |
| `dynamic_time_warping.adb` | Classic + banded DP |
| `tests.adb` | Standalone test main |
| `dynamic_time_warping.gpr` | GNAT project |
| `Makefile` | `make` / `make test` / `make clean` |

No `main.adb` — `tests.adb` is the sole main.

## License

Educational reference material. Use freely for learning Ada and DTW.
