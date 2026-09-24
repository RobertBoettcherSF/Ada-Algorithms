# Golden-section search in Ada 2023

A compact, warning-clean Ada implementation of the dedicated
[golden-section search](https://en.wikipedia.org/wiki/Golden-section_search)
algorithm for bounded one-dimensional optimization. It minimizes or maximizes
a unimodal scalar function, reports the surviving bracket, and includes the
closely related Fibonacci search.

## Theory

For a unimodal objective $f$ on $[a,b]$, golden-section search keeps two
interior probes. The golden ratio and reusable probe ratio are

$$
\varphi = \frac{1+\sqrt{5}}{2}, \qquad
\tau = \frac{1}{\varphi} = \varphi-1 \approx 0.6180339887.
$$

The probes are

$$
c=b-\tau(b-a), \qquad d=a+\tau(b-a).
$$

For minimization, if $f(c) \le f(d)$ the right portion is discarded;
otherwise the left portion is discarded. Maximization reverses the comparison.
One old probe is reused, so every iteration after initialization costs one new
objective evaluation. The bracket width contracts deterministically:

$$
\Delta x_k = \tau^k \Delta x_0.
$$

Thus an approximate iteration count for absolute tolerance $\epsilon$ is

$$
k \ge \frac{\log(\epsilon/\Delta x_0)}{\log(\tau)}.
$$

The method needs no derivatives and is robust, but it assumes unimodality on
the supplied interval. If the unique extremum is at a boundary, endpoint
comparison in this implementation returns that boundary. Flat or multimodal
objectives do not provide a unique-extremum guarantee.

Fibonacci search replaces the constant limiting ratio by ratios of consecutive
Fibonacci numbers. For a predetermined finite evaluation budget it gives the
finite-horizon analogue whose ratios approach $\tau$.

## API

`Golden_Section_Search` defines:

- `Scalar` and callback type `Scalar_Fn`;
- `Search_Config` with `Tol` and `Max_Iterations`;
- `Search_Result` with `X_Star`, `F_Star`, `Iterations`, and `Bracket`;
- `Minimize` and `Maximize` for golden-section search;
- `Fibonacci_Search` with `Find_Minimum` or `Find_Maximum` mode;
- `Near`, constants `Golden_Ratio` and `Tau`, and `Golden_Probes`;
- demos `Quartic_Unimodal`, `Negative_Quadratic_Max`, and
  `Sphere_On_Line` (plus monotone boundary objectives used by tests).

Invalid intervals with $a \ge b$ and nonpositive tolerances raise
`Constraint_Error`. `Max_Iterations = 0` is valid and returns the best sampled
point without a reduction step.

## Demo objectives

The quartic has its minimum at $x=1.5$:

$$
f(x)=(x-1.5)^4+0.1(x-1.5)^2.
$$

The concave quadratic has its maximum at $x=3$:

$$
g(x)=-(x-3)^2.
$$

`Sphere_On_Line` restricts the three-dimensional sphere to
$(1,-2,3)+x(-1,2,-3)$, whose minimum is at $x=1$.

## Build and test

Requirements: GNAT with Ada 2022 language-mode support and GNU Make. GNAT's
`-gnat2022` switch is the compiler mode currently used for Ada 2023-era code.

```sh
make clean && make
make test
```

The build uses `gnatmake -gnatwa -gnat2022`. The test executable performs well
over 100 checks covering known minima and maxima, boundary extrema, invalid
intervals, tolerance-driven shrinking, iteration caps, probe identities, and
Fibonacci search.

## Relationship to Ada-Line-Search

The sibling [Ada-Line-Search](https://github.com/RobertBoettcherSF/Ada-Line-Search) repository includes a
golden-section routine in a broader optimization line-search toolkit. This
repository is the dedicated Wikipedia algorithm presentation: a focused API,
full ratio and convergence theory, endpoint behavior, Fibonacci search, and
standalone tests.

## Files

- `golden_section_search.ads` — public API
- `golden_section_search.adb` — implementation and demo objectives
- `golden_section_search.gpr` — GNAT project
- `tests.adb` — executable test suite
- `Makefile` — build, test, and clean targets
- `README.md` — theory and usage
- `.gitignore` — build artifacts
