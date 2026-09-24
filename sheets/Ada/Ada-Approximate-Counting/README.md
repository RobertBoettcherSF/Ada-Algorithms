# Approximate Counting Algorithm (Morris Counter) — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Approximate counting algorithm](https://en.wikipedia.org/wiki/Approximate_counting_algorithm)
— **Robert Morris**'s probabilistic counter (Bell Labs, 1977/1978), analysed in
detail by **Philippe Flajolet** (INRIA; *BIT* 25, 1985), who coined the name
*approximate counting*.

The counter stores only an **exponent** $c$ and estimates a large event count
$n$ with a small amount of memory. It is a classic precursor of
**streaming algorithms** and frequency-moment estimation (cf. HyperLogLog).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **State** | Store exponent $c\in\mathbb{N}$ | Memory = bits for $c$ |
| **Increment** | Succeed with $p=b^{-c}$ | Classic $b=2$: $p=2^{-c}$ |
| **Coin flips** | AND of $c$ fair bits / $U\sim\mathrm{Unif}[0,1)$ | Equivalent tests |
| **Estimate** | $\hat n=(b^c-1)/(b-1)$ | Unbiased (Flajolet / Morris) |
| **Base 2** | $\hat n=2^c-1$ | Fully tested default |
| **Wiki approx** | $b^c$ (powers of two) | Separate from unbiased $\hat n$ |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Counter`, `Real`, `Exponent_Value`, `Base_Value` | Domain model |
| Setup | `Create`, `Exponent`, `Base_Of` | Construct / inspect |
| Estimate | `Estimate`, `Power_Approximation`, `Expectation_Given_Exponent` | $\hat n$, wiki $b^c$, wiki E-column |
| Update | `Increment`, `Increment_With_Probability`, `Increment_Many` | Probabilistic / injected / batch |
| RNG | `Seed_RNG`, `Next_Unit` | Seeded LCG on $[0,1)$ |
| Helpers | `Near`, `Power`, `Increment_Probability` | Numerics / $p=b^{-c}$ |

Strong typing uses domain types (`Real` digits 12, `Unit_Interval`, …).
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Formula summary (Morris / Flajolet)

### Increment (base $b>1$)

Let $c$ be the stored exponent. On each increment request, draw
$U\sim\mathrm{Uniform}[0,1)$ and set

$$
c \leftarrow c+1
\quad\text{with probability}\quad
p = b^{-c},
$$

else leave $c$ unchanged. For the classic base $b=2$:

$$
p = 2^{-c}.
$$

Equivalently (Wikipedia): generate $c$ fair coin flips and increment only if
**all** are heads — the AND of $c$ random bits has success probability
$2^{-c}$.

When $c=0$, $p=b^{0}=1$: the first increment **always** succeeds.

### Unbiased estimator

The standard Morris / Flajolet unbiased estimator of the true count $n$ is

$$
\hat n = \frac{b^{c}-1}{b-1}.
$$

For **base 2** this reduces to

$$
\hat n = 2^{c}-1,
$$

and satisfies $\mathbb{E}[\hat n]=n$ (starting from $c=0$). This package's
`Estimate` returns that value.

### Wikipedia “Approximation” column

Wikipedia also tabulates the **power** $b^{c}$ (for $b=2$: $1,2,4,8,16,32,\ldots$)
as an order-of-magnitude “Approximation”. That is **not** the unbiased
estimator. Use `Power_Approximation` for $b^{c}$ and `Estimate` for
$\hat n=(b^{c}-1)/(b-1)$.

| Stored $c$ | Approximation $2^{c}$ | Unbiased $\hat n=2^{c}-1$ | Wiki E (large $n$) $\approx 2^{c+1}-2$ |
| --- | --- | --- | --- |
| 0 | 1 | 0 | 0 |
| 1 | 2 | 1 | 2 |
| 2 | 4 | 3 | 6 |
| 3 | 8 | 7 | 14 |
| 4 | 16 | 15 | 30 |
| 5 | 32 | 31 | 62 |

`Expectation_Given_Exponent` matches the wiki Base-2 expectation column
$2^{c+1}-2=2(2^{c}-1)$.

### Example

To move from approximation $4$ ($c=2$) toward $8$ ($c=3$), increment with
probability $p=2^{-2}=1/4$; otherwise remain at $c=2$.

## Usage

```ada
with Approximate_Counting; use Approximate_Counting;

procedure Demo is
   C : Counter := Create;           -- c = 0, base 2
   S : RNG_State;
begin
   Seed_RNG (S, Seed => 42);
   Increment_Many (C, 10_000, S);
   -- Estimate ≈ order of 10000; Exponent is small (log-scale)
end Demo;
```

Deterministic testing with injected uniforms:

```ada
C : Counter := Create;
-- Force success path: U = 0 < p for any finite c
Increment_With_Probability (C, 0.0);  -- c becomes 1
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Papproximate_counting.gpr`. Main program is
`tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `approximate_counting.ads` | Package spec |
| `approximate_counting.adb` | Package body |
| `approximate_counting.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Morris, R. *Counting large numbers of events in small registers*.
  Communications of the ACM 21, 10 (1978), 840–842.
- Flajolet, P. *Approximate Counting: A Detailed Analysis*. BIT 25 (1985),
  113–134.
- Wikipedia: [Approximate counting algorithm](https://en.wikipedia.org/wiki/Approximate_counting_algorithm).
- Nelson, J.; Yu, H. *Optimal bounds for approximate counting*. arXiv:2010.02116
  (2020).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
