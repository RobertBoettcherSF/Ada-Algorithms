# Hidden Markov Model — Survey (Ada 2023)

Educational Ada 2023 **umbrella / survey** package for
[Wikipedia: Hidden Markov model](https://en.wikipedia.org/wiki/Hidden_Markov_model).
A discrete **HMM** pairs a hidden Markov chain $X_t$ with emissions $Y_t$
that depend only on the current hidden state. Classic inference tasks are
likelihood of observations, filtering, smoothing, the most likely state
path, and learning parameters from data.

This repository embeds **compact, self-contained** implementations covering
the Wikipedia definition and inference/learning sections: sampling, scaled
forward likelihood, filtering / forward–backward smoothing, Viterbi
decoding, and Baum–Welch EM. Deeper treatments of individual algorithms
live in sibling Ada algorithm repos (see below). This package does **not**
depend on those siblings.

Based on Rabiner’s tutorial and the Wikipedia HMM / Viterbi /
forward–backward / Baum–Welch pages.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Inference / task | Approach | Notes |
| --- | --- | --- |
| **Definition** | `HMM` ($N$, $M$, $\pi$, $A$, $B$) | Discrete states & symbols |
| **Validation** | `Is_Valid_HMM` / `Normalize_Rows` / `Near` | Stochastic row checks |
| **Generation** | `Sample_Path` / `Sample_Observations` | Seeded LCG |
| **Likelihood** | `Log_Likelihood` / `Likelihood` | Scaled forward ($c_t$) |
| **Filtering** | `Filter` | $P(X_t \mid o_{1:t})$ = scaled $\alpha_t$ |
| **Smoothing** | `Smooth` / `Forward_Backward` | $\gamma_t$, optional $\xi$ |
| **MAP marginal path** | `Posterior_Mode_Path` | $\arg\max_i \gamma_t(i)$ |
| **Most likely path** | `Viterbi_Decode` / `Viterbi_Decode_Log` | Product / log-domain DP |
| **Learning** | `Baum_Welch_Fit` | EM; Max_Iter / Tol → `Fit_Result` |
| **Fixture** | `Make_Doctor_Fever_HMM` | Wikipedia Healthy / Fever |

## Sibling repositories (deeper treatments)

| Topic | Repository |
| --- | --- |
| Viterbi (most likely path) | [Ada-Viterbi](https://github.com/RobertBoettcherSF/Ada-Viterbi) |
| Forward–backward (smoothing) | [Ada-Forward-Backward](https://github.com/RobertBoettcherSF/Ada-Forward-Backward) |
| Baum–Welch (EM learning) | [Ada-Baum-Welch](https://github.com/RobertBoettcherSF/Ada-Baum-Welch) |

This survey package does **not** depend on those packages; algorithms are
embedded compactly for the umbrella topic.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `HMM`, `FB_Result`, `Viterbi_Result`, `Fit_Result` | Domain model |
| Hygiene | `Is_Valid_HMM`, `Normalize_Rows`, `Near`, `Log`, `Exp` | Contracts / numerics |
| Init | `Make_Doctor_Fever_HMM`, `Random_Init_HMM` | Fixtures / EM start |
| Sample | `Sample_Path`, `Sample_Observations` | Synthetic data |
| Likelihood | `Log_Likelihood`, `Likelihood` | $P(o)$, $\log P(o)$ |
| Filter / smooth | `Filter`, `Smooth`, `Forward_Backward` | $\alpha$, $\gamma$, $\xi$ |
| Mode | `Posterior_Mode_Path` | Marginal MAP path |
| Viterbi | `Viterbi_Decode`, `Viterbi_Decode_Log`, `Path_Probability` | Joint MAP path |
| EM | `Baum_Welch_Fit` | Parameter learning |

Strong typing uses domain types (`Real` digits 12, `Probability`,
`Log_Probability`, …). Public subprograms carry `Pre` / `Post` / `Global`
where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`, `Did_Not_Converge`.

### Smoothing vs Viterbi

| Task | Algorithm | Output |
| --- | --- | --- |
| **Most likely path** | Viterbi | $\arg\max_{x_{1:T}} P(x_{1:T}, o_{1:T})$ |
| **Per-time posteriors** | Forward–backward | $\gamma_t(i)=P(X_t=i\mid o_{1:T})$ |

The sequence of individually most probable states
$\arg\max_i\gamma_t(i)$ (`Posterior_Mode_Path`) is a **MAP marginal
path**. It can differ from the Viterbi path because marginal modes ignore
joint path constraints. On the classic doctor/fever example they coincide.

### Doctor / fever fixture

States: Healthy (1), Fever (2). Symbols: normal (1), cold (2), dizzy (3).

Observations `[normal, cold, dizzy]` → Viterbi path
**Healthy, Healthy, Fever** with joint path probability **0.01512**
(Wikipedia Viterbi example table).

## Usage

```bash
cd /workspace/ada-hidden-markov-model
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

```ada
with Hidden_Markov_Model; use Hidden_Markov_Model;

Model : constant HMM := Make_Doctor_Fever_HMM;
Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
Path  : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
LL    : constant Log_Probability := Log_Likelihood (Model, Obs);
FB    : constant FB_Result := Forward_Backward (Model, Obs);
```

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Numeric helpers (`Near` / `Log` / `Exp`)
- HMM validation and `Normalize_Rows`
- Seeded `Random_Init_HMM`
- Wikipedia doctor/fever Viterbi path and known probability 0.01512
- Viterbi beats alternate paths; path scoring
- Scaled-forward likelihood finite / matches wiki order
- Filter and Smooth $\gamma$ row sums
- Posterior mode vs Viterbi (coincide on fixture; may differ in general)
- Sampling reproducibility
- Baum–Welch likelihood increase and sample+refit sanity
- Invalid / degenerate exception paths

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `hidden_markov_model.gpr`:

```ada
project Hidden_Markov_Model is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Hidden_Markov_Model;
```

## Layout

Root only (no `src/`, no `main.adb`):

- `hidden_markov_model.ads` / `.adb` / `.gpr`
- `Makefile`, `tests.adb`, `README.md`, `.gitignore`

## References

1. L. R. Rabiner, “A tutorial on Hidden Markov Models and selected
   applications in speech recognition,” *Proc. IEEE*, 77(2):257–286, 1989.
2. [Wikipedia: Hidden Markov model](https://en.wikipedia.org/wiki/Hidden_Markov_model)
3. [Wikipedia: Viterbi algorithm](https://en.wikipedia.org/wiki/Viterbi_algorithm)
4. [Wikipedia: Forward–backward algorithm](https://en.wikipedia.org/wiki/Forward%E2%80%93backward_algorithm)
5. [Wikipedia: Baum–Welch algorithm](https://en.wikipedia.org/wiki/Baum%E2%80%93Welch_algorithm)
