# Baum–Welch Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Baum–Welch algorithm](https://en.wikipedia.org/wiki/Baum%E2%80%93Welch_algorithm)
— an [expectation–maximization](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm)
(EM) method for training discrete
[hidden Markov models](https://en.wikipedia.org/wiki/Hidden_Markov_model)
$\theta = (A, B, \pi)$.

The **E-step** uses scaled forward–backward to obtain posteriors $\gamma$
and pairwise posteriors $\xi$; the **M-step** applies Rabiner / Wikipedia
parameter updates. This repository embeds a compact scaled forward–backward
implementation and does **not** depend on the sibling packages.

## EM overview

| Step | Role | Formula (sketch) |
| --- | --- | --- |
| **E-step** | Forward–backward | $\gamma_i(t)=\dfrac{\alpha_i(t)\beta_i(t)}{\sum_j\alpha_j(t)\beta_j(t)}$, $\xi_{ij}(t)=\dfrac{\alpha_i(t)a_{ij}b_j(y_{t+1})\beta_j(t+1)}{\mathrm{denom}}$ |
| **M-step** | Update $\pi,A,B$ | $\pi_i^*=\gamma_i(1)$, $a_{ij}^*=\dfrac{\sum_t\xi_{ij}(t)}{\sum_t\gamma_i(t)}$, $b_i^*(v_k)=\dfrac{\sum_{t:y_t=v_k}\gamma_i(t)}{\sum_t\gamma_i(t)}$ |
| **Iterate** | Until convergence | Stop when $\lvert\log L_{\mathrm{new}}-\log L_{\mathrm{old}}\rvert < \mathrm{Tol}$ or `Max_Iter` |

Optional **multi-sequence** pooling follows Wikipedia: average $\gamma_{\cdot}(1)$
across sequences for $\pi$, and pool $\xi/\gamma$ numerators and denominators
for $A$ and $B$.

Likelihood is **monotone non-decreasing** (within numerical tolerance) when
the scaled forward likelihood is consistent with the $\gamma/\xi$ used in
the M-step. Baum–Welch finds a **local** maximum and can over-fit.

## Scaling note (Rabiner $c_t$)

Unscaled $\alpha$ underflows on longer sequences. This package uses
Rabiner-style scaling: at each $t$, $c_t=\sum_i\alpha'_t(i)$ and
$\hat\alpha_t=\alpha'_t/c_t$. Then

$$
P(y)=\prod_{t=1}^{T} c_t,\qquad
\log P(y)=\sum_{t=1}^{T}\log c_t.
$$

Scaled $\hat\beta$ uses the same $c_t$; $\gamma$ and $\xi$ are true
posteriors suitable for the M-step.

Complexity $O(N^2 T)$ per EM iteration ($N$ = states, $T$ = length).

## Project Overview

| Concern | API | Notes |
| --- | --- | --- |
| Types | `HMM`, `E_Step_Result`, `Fit_Result` | Caps: `Max_States/Symbols/Time/Sequences` |
| Likelihood | `Likelihood`, `Log_Likelihood` | Via scaled forward |
| E-step | `E_Step` | Scaled $\alpha,\beta,\gamma,\xi$ |
| One EM step | `Baum_Welch_Step` | Single-sequence update |
| Fit | `Baum_Welch_Fit` | Tol / Max_Iter / history / converge flag |
| Multi | `Baum_Welch_Fit_Multi` | Wikipedia pooling |
| Init | `Random_Init_HMM`, `Sample_Observations` | Seeded LCG |
| Fixture | `Make_Doctor_Fever_HMM` | Doctor / fever tables |
| Hygiene | `Is_Valid_HMM`, `Normalize_Rows`, `Row_Stochastic`, `Near` | |

Language: **Ada 2023** (ISO/IEC 8652:2023), GNAT `-gnat2022`.
`pragma Ada_2022;`, `SPARK_Mode => Off`. Named exceptions:
`Invalid_Argument`, `Degenerate_Geometry`, `Capacity_Exceeded`,
`Did_Not_Converge`.

## Usage

```ada
with Baum_Welch; use Baum_Welch;

procedure Demo is
   Truth : constant HMM := Make_Doctor_Fever_HMM;
   Obs   : constant Observation_Sequence :=
     Sample_Observations (Truth, 100, Seed => 1);
   Init  : constant HMM := Random_Init_HMM (2, 3, Seed => 42);
   Fit   : constant Fit_Result :=
     Baum_Welch_Fit (Init, Obs, Max_Iter => 50, Tol => 1.0E-6);
begin
   --  Fit.Model, Fit.Log_Likelihood, Fit.Converged, Fit.Iterations
   null;
end Demo;
```

One EM iteration:

```ada
Next : constant HMM := Baum_Welch_Step (Init, Obs);
```

Multi-sequence:

```ada
Fit := Baum_Welch_Fit_Multi (Init, Data, Lengths, Max_Iter => 40);
```

## Building

```bash
cd /workspace/ada-baum-welch
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pbaum_welch.gpr` (zero warnings expected).

## Testing

```bash
make test
```

Standalone `tests.adb` (≥13 sections, Check-based assertions,
`pragma Assert (Fail_Count = 0)`). Covers stochastic updates, monotone
likelihood, synthetic recovery, multi-sequence pooling, invalid inputs,
convergence flags, deterministic emissions, and $\gamma/\xi$ consistency.

## Layout

Root-only sources (no `src/`, no `main.adb`):

- `baum_welch.ads` / `baum_welch.adb` / `baum_welch.gpr`
- `Makefile`, `tests.adb`, `README.md`, `.gitignore`

## Related siblings

These are **sibling educational repos**, not build dependencies:

- **Forward–backward** — smoothing posteriors $\gamma_t(i)$, scaled FB
- **Viterbi** — most likely state path
- **HMM** — shared discrete HMM vocabulary (if present)

## References

- Wikipedia: [Baum–Welch algorithm](https://en.wikipedia.org/wiki/Baum%E2%80%93Welch_algorithm)
- L. R. Rabiner, “A Tutorial on Hidden Markov Models and Selected
  Applications in Speech Recognition,” *Proc. IEEE*, 1989.
