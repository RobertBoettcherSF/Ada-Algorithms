# Forward–Backward Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Forward–backward algorithm](https://en.wikipedia.org/wiki/Forward%E2%80%93backward_algorithm)
— an inference method for discrete
[hidden Markov models](https://en.wikipedia.org/wiki/Hidden_Markov_model)
that computes **smoothed** posterior marginals

$$
\gamma_t(i) = P(X_t = i \mid o_{1:T})
$$

together with forward probabilities $\alpha$, backward probabilities
$\beta$, and the observation likelihood $P(o_{1:T})$.

## Smoothing vs Viterbi decoding

| Task | Algorithm | Output |
| --- | --- | --- |
| **Most likely path** | [Viterbi](https://en.wikipedia.org/wiki/Viterbi_algorithm) | $\arg\max_{x_{1:T}} P(x_{1:T}, o_{1:T})$ |
| **Per-time posteriors** | Forward–backward | $\gamma_t(i) = P(X_t=i \mid o_{1:T})$ |

The sequence of individually most probable states
$\arg\max_i \gamma_t(i)$ (this package’s `Posterior_Mode_Path`) is a
**MAP marginal path**. It can differ from the Viterbi path because
marginal modes ignore joint path constraints. On the classic doctor/fever
example they happen to coincide.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Forward** | `Forward` / `Likelihood_From_Alpha` | Unscaled $\alpha$; $P(o)=\sum_i\alpha_T(i)$ |
| **Backward** | `Backward` | Unscaled $\beta_T=1$ |
| **Smooth** | `Smooth` / `Forward_Backward` | $\gamma$, optional $\xi$ |
| **Scaled** | `Forward_Backward_Scaled` | Rabiner $c_t$; preferred for long $T$ |
| **Mode path** | `Posterior_Mode_Path` | $\arg\max_i\gamma_t(i)$ |
| **Fixture** | `Make_Doctor_Fever_HMM` | Wikipedia doctor / fever example |
| **HMM hygiene** | `Is_Valid_HMM` / `Normalize_Rows` | Stochastic checks / row renorm |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `HMM`, `FB_Result`, $\alpha/\beta/\gamma/\xi$ tables | Domain model |
| Unscaled FB | `Forward`, `Backward`, `Smooth`, `Forward_Backward` | Short sequences |
| Scaled FB | `Forward_Backward_Scaled` | Numerical stability |
| Helpers | `Near`, `Log`, `Exp`, `Log_Sum_Exp*` | Numerics |
| Fixture | `Make_Doctor_Fever_HMM`, state/symbol constants | Wiki example |

Strong typing uses domain types (`Real` digits 12, `Probability`,
`Log_Probability`, …). Public subprograms carry `Pre` / `Post` / `Global`
where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formulas

**Forward (unscaled)**

$$
\alpha_1(i)=\pi_i\,b_i(o_1),\qquad
\alpha_{t+1}(j)=\Bigl(\sum_i \alpha_t(i)\,a_{ij}\Bigr)\,b_j(o_{t+1}),\qquad
P(o)=\sum_i\alpha_T(i).
$$

**Backward**

$$
\beta_T(i)=1,\qquad
\beta_t(i)=\sum_j a_{ij}\,b_j(o_{t+1})\,\beta_{t+1}(j).
$$

**Smoothed posteriors / pairwise**

$$
\gamma_t(i)=\frac{\alpha_t(i)\,\beta_t(i)}{P(o)},\qquad
\xi_t(i,j)=\frac{\alpha_t(i)\,a_{ij}\,b_j(o_{t+1})\,\beta_{t+1}(j)}{P(o)}.
$$

Identity used in tests: $\sum_j\xi_t(i,j)=\gamma_t(i)$.

### Scaled note (Rabiner $c_t$)

At each $t$, divide the forward vector by $c_t=\sum_i\alpha'_t(i)$ so
scaled $\hat\alpha_t$ sums to 1. Apply the same $c_t$ when forming
scaled $\hat\beta$. Then

$$
P(o)=\prod_{t=1}^{T} c_t,\qquad
\log P(o)=\sum_{t=1}^{T}\log c_t,
$$

and $\gamma_t(i)=\hat\alpha_t(i)\,\hat\beta_t(i)$ (renormalised if needed).
Unscaled $\alpha$ **underflows** on longer sequences; use
`Forward_Backward_Scaled` in practice. `Log_Sum_Exp` helpers support
log-domain likelihood bookkeeping.

Complexity $O(N^2 T)$ time, $O(N T)$ space ($N$ = states).

## Wikipedia doctor / fever example

States: **Healthy**, **Fever**. Observations: **normal**, **cold**, **dizzy**.

```
init  = {Healthy: 0.6, Fever: 0.4}
trans = Healthy→{H:0.7, F:0.3}, Fever→{H:0.4, F:0.6}
emit  = Healthy→{normal:0.5, cold:0.4, dizzy:0.1}
        Fever  →{normal:0.1, cold:0.3, dizzy:0.6}
```

(Same tables as the Viterbi sibling; end-state mass from the Python
listing is folded into the stay probabilities.)

For `normal, cold, dizzy`:

- $P(o)\approx 0.03628$
- Posterior mode path **(Healthy, Healthy, Fever)**
- $\gamma_1(\mathrm{Healthy})\approx 0.877$,
  $\gamma_3(\mathrm{Fever})\approx 0.788$

## Usage

```ada
with Forward_Backward; use Forward_Backward;

declare
   Model : constant HMM := Make_Doctor_Fever_HMM;
   Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
   R     : constant FB_Result :=
     Forward_Backward_Scaled (Model, Obs, Fill_Xi => True);
   Path  : constant State_Sequence := Posterior_Mode_Path (R.Gamma);
begin
   --  Path = (Healthy, Healthy, Fever)
   --  R.Likelihood ≈ 0.03628; R.Gamma rows sum to 1
   null;
end;
```

## Building

```bash
cd /workspace/ada-forward-backward
make clean && make          # gnatmake -gnatwa -gnat2022 -Pforward_backward.gpr
make test                   # run bin/tests; expects Fail_Count = 0
```

Root layout only (no `src/`, no `main.adb`):

```
forward_backward.ads  forward_backward.adb  forward_backward.gpr
Makefile              tests.adb             README.md   .gitignore
```

## Testing

`tests.adb` is the main program (≥13 sections, 100+ `Check` assertions):
helpers / LogSumExp, HMM validation, fixture constants, hand-worked
$\alpha/\beta/\gamma$, $\xi$ marginalization, scaled↔unscaled agreement,
posterior mode path, empty/invalid exceptions, deterministic HMM,
long-sequence scaled stability (unscaled may underflow), single-obs edge,
uniform noise sanity.

## Related (siblings, not dependencies)

Educational siblings in the same Ada collection (import nothing from them):

- **Viterbi algorithm** — most likely hidden-state sequence
- **Baum–Welch algorithm** — EM training of HMM parameters (uses $\gamma,\xi$)

This package is intentionally **self-contained**: no `with` of other
`Ada-*` algorithm packages. Compact HMM types and the doctor/fever fixture
are duplicated here on purpose.

## License / intent

Educational reference implementation aligned with the Wikipedia article and
Rabiner’s HMM tutorial. Not a production ASR library.
