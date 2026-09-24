# Viterbi Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Viterbi algorithm](https://en.wikipedia.org/wiki/Viterbi_algorithm)
— a **dynamic programming** method that finds the most likely sequence of
hidden states (the **Viterbi path**) given a discrete
[hidden Markov model](https://en.wikipedia.org/wiki/Hidden_Markov_model)
(HMM) and an observation sequence.

Named after [Andrew Viterbi](https://en.wikipedia.org/wiki/Andrew_Viterbi),
who proposed it in **1967** as a decoding algorithm for convolutional codes
over noisy digital links. It is now standard in speech recognition,
computational linguistics, bioinformatics, and digital communications
(CDMA/GSM, satellite, 802.11).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Product decode** | `Viterbi_Decode` | Classic Wikipedia recurrence (tiny examples) |
| **Log decode** | `Viterbi_Decode_Log` | Stable max of sum-of-logs (preferred) |
| **Path score** | `Path_Probability` / `Log_Path_Probability` | Exact score of a given state path |
| **Fixture** | `Make_Doctor_Fever_HMM` | Wikipedia doctor / fever example |
| **HMM hygiene** | `Is_Valid_HMM` / `Normalize_Rows` | Stochastic checks / row renorm |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `HMM`, `Viterbi_Result`, matrices / sequences | Domain model |
| Decode | `Viterbi_Decode`, `Viterbi_Decode_Log` | Most-likely path |
| Scoring | `Path_Probability`, `Log_Path_Probability` | Verify / compare paths |
| Helpers | `Near`, `Log`, `Exp`, `Argmax_*` | Numerics |
| Fixture | `Make_Doctor_Fever_HMM`, state/symbol constants | Wiki example |

Strong typing uses domain types (`Real` digits 12, `Probability`,
`Log_Probability`, …). Public subprograms carry `Pre` / `Post` / `Global`
where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Algorithm

Given hidden states $S$, emissions $M$, and observations
$o_0,\ldots,o_{T-1}$, two tables of size $T\times|S|$ are built:

- $P_{t,s}$: maximum probability of ending in state $s$ at time $t$
- $Q_{t,s}$: backpointer (previous state on that best path)

Recurrence:

$$
P_{t,s}=
\begin{cases}
\pi_s\cdot b_{s,o_t} & t=0,\\[4pt]
\max_{r\in S}\bigl(P_{t-1,r}\cdot a_{r,s}\cdot b_{s,o_t}\bigr) & t>0.
\end{cases}
$$

$Q_{t,s}$ uses $\arg\max$ in place of $\max$ ($Q_{0,s}=0$).
The Viterbi path is recovered by taking $\arg\max_s P_{T-1,s}$ and
following backpointers in reverse. Time complexity
$O(T\cdot|S|^2)$.

## Pseudocode summary

```
prob[0][s] = init[s] * emit[s][obs[0]]
for t = 1 .. T-1:
  for s:
    for r:
      new = prob[t-1][r] * trans[r][s] * emit[s][obs[t]]
      keep max + prev
backtrace from argmax at T-1
```

### Log-domain (preferred)

$$
L_{t,s}
=
\log b_{s,o_t}
+
\max_r\bigl(L_{t-1,r}+\log a_{r,s}\bigr)
$$

Uses only `max` of sums of logs (no log-sum-exp). Avoids underflow on
long sequences while returning the same path as the product form on
well-scaled tiny examples.

## Wikipedia doctor / fever example

States: **Healthy**, **Fever**. Observations: **normal**, **cold**, **dizzy**.

```
init  = {Healthy: 0.6, Fever: 0.4}
trans = Healthy→{H:0.7, F:0.3}, Fever→{H:0.4, F:0.6}
emit  = Healthy→{normal:0.5, cold:0.4, dizzy:0.1}
        Fever  →{normal:0.1, cold:0.3, dizzy:0.6}
```

Observation sequence `normal, cold, dizzy` yields Viterbi path
**(Healthy, Healthy, Fever)** with probability **0.01512** (see the
Wikipedia table of DP cells).

In this package: state indices `Healthy=1`, `Fever=2`; symbols
`Normal=1`, `Cold=2`, `Dizzy=3`; fixture `Make_Doctor_Fever_HMM`.

## Usage

```ada
with Viterbi; use Viterbi;

declare
   Model : constant HMM := Make_Doctor_Fever_HMM;
   Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
   R     : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
begin
   --  R.Path = (Healthy, Healthy, Fever)
   --  Exp (R.Log_Probability) ≈ 0.01512
   null;
end;
```

## Building

```bash
cd /workspace/ada-viterbi
make clean && make          # gnatmake -gnatwa -gnat2022 -Pviterbi.gpr
make test                   # run bin/tests; expects Fail_Count = 0
```

Root layout only (no `src/`, no `main.adb`):

```
viterbi.ads  viterbi.adb  viterbi.gpr
Makefile     tests.adb    README.md   .gitignore
```

## Testing

`tests.adb` is the main program (≥13 sections, 100+ `Check` assertions):
HMM validation, single-observation argmax, deterministic chain, Wikipedia
fever path + DP table, log/product agreement, path optimality over all
alternates, empty/bad-symbol exceptions, uniform noise sanity, hand-worked
2×3 trellis backpointers, degenerate emissions, fixture constants, longer
sequence stability.

## Related (siblings, not dependencies)

Educational siblings in the same Ada collection (import nothing from them):

- **Forward–backward algorithm** — posterior state / occupancy probabilities
- **Baum–Welch algorithm** — EM training of HMM parameters
- Generic HMM utilities

This package is intentionally **self-contained**: no `with` of other
`Ada-*` algorithm packages.

## License / intent

Educational reference implementation aligned with the Wikipedia article and
Viterbi (1967) / Rabiner HMM tutorial material. Not a production ASR or
codec library.
