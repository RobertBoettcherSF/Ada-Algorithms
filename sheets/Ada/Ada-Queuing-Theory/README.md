# Queuing Theory — Survey (Ada 2023)

Educational Ada 2023 **umbrella / survey** package for
[Wikipedia: Queueing theory](https://en.wikipedia.org/wiki/Queueing_theory).
**Queueing theory** is the mathematical study of waiting lines (queues):
arrival processes, service mechanisms, and performance metrics such as
mean system size $L$, mean wait $W$, and utilization.

This repository embeds compact, self-contained **single-node** formulas:
Little's law, Kendall notation helpers, traffic intensity, **M/M/1**,
**M/M/c** (Erlang-C), **M/M/1/K**, **M/M/∞**, and birth–death local-balance
checks. It does **not** implement closed queueing networks; see the sibling
[Ada-Buzens-Algorithm](https://github.com/RobertBoettcherSF/Ada-Buzens-Algorithm)
for Gordon–Newell normalizing constants via Buzen convolution.

Based on Erlang's teletraffic models (1909+), Kendall's notation (1953),
and standard treatments (Kleinrock; Gross & Harris).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Little's law** | $L=\lambda W$ rearrangements | Positivity contracts |
| **Kendall notation** | `Format_Kendall` / lite parse | A/S/c(/K/N/D) |
| **Traffic intensity** | $\rho=\lambda/(c\mu)$ | Stability helpers |
| **M/M/1** | Geometric steady state | $\rho<1$ required |
| **M/M/c** | Erlang-C + finite sum $P_0$ | Real iterative products |
| **M/M/1/K** | Truncated geometric | Blocking $P_K$ |
| **M/M/∞** | Poisson counts | $L=\lambda/\mu$ |
| **Birth–death** | Local balance $\mu P_n=\lambda P_{n-1}$ | Educational verify |

## Sibling note (closed networks)

| Topic | Repository |
| --- | --- |
| Closed networks / convolution | [Ada-Buzens-Algorithm](https://github.com/RobertBoettcherSF/Ada-Buzens-Algorithm) |

This survey package does **not** depend on Buzen; mention it only as the
place for product-form closed networks and the normalizing constant $G(N)$.

## Features

| Area | Subprograms | Role |
| --- | --- | --- |
| Little | `Littles_L`, `Littles_W`, `Littles_Lambda` | $L=\lambda W$ |
| Kendall | `Format_Kendall`, `Parse_Kendall_Servers` | Notation helper |
| Intensity | `Rho`, `Is_Stable_MM1`, `Is_Stable_MMc` | $\rho$ / stability |
| M/M/1 | `MM1_P0`, `MM1_Pn`, `MM1_L`, `MM1_Lq`, `MM1_W`, `MM1_Wq`, `MM1_Utilization`, `Analyze_MM1` | Classic formulas |
| M/M/c | `MMc_P0`, `MMc_Erlang_C`, `MMc_Lq`, `MMc_Wq`, `MMc_L`, `MMc_W`, `Analyze_MMc` | Multi-server |
| M/M/1/K | `MM1K_Pn`, `MM1K_P_Block`, `MM1K_Lambda_Eff`, `MM1K_L`, `MM1K_Lq`, `MM1K_W`, `MM1K_Wq`, `Analyze_MM1K` | Finite buffer |
| M/M/∞ | `MM_Inf_L`, `MM_Inf_Pn`, `MM_Inf_W`, `Analyze_MM_Inf` | Infinite servers |
| Balance | `MM1_Local_Balance_Holds`, `Birth_Death_Pn_Product` | Birth–death sketch |
| Helpers | `Near`, `Power`, `Factorial_Real` | Numeric utilities |

Strong typing uses domain types (`Real` digits 12, `MM1_Result`,
`MMc_Result`, `MM1K_Result`, `MM_Inf_Result`, Kendall enums).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry` (unstable
$\rho\ge 1$ for infinite-buffer models), `Capacity_Exceeded`,
`Empty_Sample` (parity slot).

### Classic M/M/1 formulas ($\rho=\lambda/\mu<1$)

$$
\begin{aligned}
P_0&=1-\rho,\quad
P_n=(1-\rho)\rho^n,\\
L&=\frac{\rho}{1-\rho},\quad
L_q=\frac{\rho^2}{1-\rho},\\
W&=\frac{1}{\mu-\lambda},\quad
W_q=\frac{\lambda}{\mu(\mu-\lambda)}.
\end{aligned}
$$

### M/M/c (Erlang-C)

With offered load $a=\lambda/\mu$ and $\rho=a/c<1$,

$$
P_0=\Biggl(\sum_{k=0}^{c-1}\frac{a^k}{k!}+\frac{a^c}{c!(1-\rho)}\Biggr)^{-1},
\quad
C(c,a)=\frac{a^c}{c!(1-\rho)}\,P_0,
\quad
L_q=C(c,a)\,\frac{\rho}{1-\rho}.
$$

Factorials and powers are formed with **Real iterative products** (no huge
integers).

## Usage

```ada
with Queuing_Theory; use Queuing_Theory;

procedure Demo is
   R : constant MM1_Result := Analyze_MM1 (Lambda => 1.0, Mu => 2.0);
   --  ρ=0.5, L=1, W=1, Lq=0.5, Wq=0.5
   C : constant MMc_Result := Analyze_MMc (5.0, 3.0, 2);
   K : constant String := Format_Kendall ("M", "M", 1);
begin
   pragma Assert (Near (R.L, 1.0));
   pragma Assert (K = "M/M/1");
   pragma Assert (C.Erlang_C > 0.0);
end Demo;
```

Validate rates: $\lambda>0$, $\mu>0$, and $\rho<1$ for M/M/1 and M/M/c.
M/M/1/K is always defined for $\lambda,\mu>0$ (including $\rho\ge 1$).

## Building

```bash
cd /workspace/ada-queuing-theory
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pqueuing_theory.gpr`. Expect **zero**
errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (Check + `pragma Assert (Fail_Count = 0)`; no
`Ada.Assertions` dependency in the harness). Coverage includes Little
identities, M/M/1 fixtures, $P_n$ sums, stability exceptions, M/M/c
reduction at $c=1$, M/M/1/K → M/M/1 for large $K$, blocking probability,
birth–death balance, Kendall format, and M/M/∞ Poisson sums.

## Layout

Root-only sources (no `src/`, no `main.adb`):

- `queuing_theory.ads` / `queuing_theory.adb` — package
- `queuing_theory.gpr` — GNAT project
- `tests.adb` — test main
- `Makefile`, `README.md`, `.gitignore`

## References

1. A. K. Erlang — teletraffic / early queueing models (1909–1920).
2. D. G. Kendall — *Stochastic Processes Occurring in the Theory of Queues*
   (1953); Kendall's notation A/S/c.
3. L. Kleinrock — *Queueing Systems*, Vol. I (Wiley, 1975/1976).
4. D. Gross & C. M. Harris — *Fundamentals of Queueing Theory*.
5. [Wikipedia: Queueing theory](https://en.wikipedia.org/wiki/Queueing_theory)
6. [Wikipedia: M/M/1 queue](https://en.wikipedia.org/wiki/M/M/1_queue),
   [M/M/c](https://en.wikipedia.org/wiki/M/M/c_queue),
   [Kendall's notation](https://en.wikipedia.org/wiki/Kendall%27s_notation)

## License

Educational / reference implementation for algorithm study.
