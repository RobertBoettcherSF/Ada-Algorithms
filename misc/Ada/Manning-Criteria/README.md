# Manning Criteria (IBS) — Ada 2023 Educational Encoding

> **NOT FOR CLINICAL USE.** This repository is an **educational / software-reference**
> encoding of the published **Manning criteria** for irritable bowel syndrome (IBS)
> for **unit testing** and algorithm pedagogy only. It is **not medical advice**,
> **not a medical device**, and **must not** guide diagnosis, triage, treatment, or
> patient counseling. Clinicians must follow **current guidelines**, local protocols,
> and clinical judgment. Do not invent or rely on this software for patient care.

Educational, self-contained Ada 2023 package implementing the **Manning diagnostic
criteria** as summarized on
[Wikipedia: Manning Criteria](https://en.wikipedia.org/wiki/Manning_Criteria)
and originally described by Manning *et al.* (*Br Med J*, 1978). The package
exposes **deterministic** pure functions that count positive symptom flags and
compare the total to a configurable threshold.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Critical disclaimer (read first)

- **Educational / software-reference only** — encodes published symptom questions
  and a count threshold for reproducible unit tests.
- **Not for clinical use** — not medical advice; not a substitute for history,
  examination, labs, imaging, or specialist evaluation.
- Thresholds of $2$, $3$, or $4$ appear in the literature; this package defaults
  to $\ge 3$ for `Is_Positive` and allows $2$–$4$ via `Meets_Threshold` /
  `Is_Positive` overloads. Choice of cutoff is a research/literature decision,
  **not** a recommendation from this software.

## History

In 1978, Manning, Thompson, Heaton, and Morris published “Towards positive
diagnosis of the irritable bowel” (*British Medical Journal*, 1978;
PMID 698649), proposing a short list of symptom questions to support a
**positive** (symptom-based) approach to IBS rather than diagnosis by exclusion
alone. The **Manning criteria** remain a historical and comparative reference
alongside later **Rome** processes (Rome I, II, III, IV) and the Kruis criteria.
A 2013 validation study reported Manning having less sensitivity but more
specificity than Rome III in secondary care (Ford *et al.*, *Gastroenterology*
2013). This repository encodes only the **six classic Manning questions** and
count logic — not Rome questionnaires.

## The six Manning criteria

From the Wikipedia list (matching Manning *et al.* / common reproductions):

| # | Criterion (educational wording) | Record field |
| --- | --- | --- |
| 1 | Onset of pain linked to more frequent bowel movements | `Pain_Linked_To_More_Frequent_Stools` |
| 2 | Looser stools associated with onset of pain | `Looser_Stools_With_Pain_Onset` |
| 3 | Pain relieved by passage of stool | `Pain_Relieved_By_Defecation` |
| 4 | Noticeable abdominal bloating | `Noticeable_Abdominal_Bloating` |
| 5 | Sensation of incomplete evacuation more than $25\%$ of the time | `Incomplete_Evacuation_GT_25_Pct` |
| 6 | Diarrhea with mucus more than $25\%$ of the time | `Diarrhea_With_Mucus_GT_25_Pct` |

Each present criterion contributes **one** point. There are no differential
weights.

## Scoring math

Let $c_i \in \{0,1\}$ for $i = 1,\ldots,6$ indicate absence/presence of each
criterion. The positive count is

$$
N = \sum_{i=1}^{6} c_i
$$

with $N \in \{0,1,2,3,4,5,6\}$.

A configurable threshold $T \in \{2,3,4\}$ yields a positive screen when

$$
N \ge T
$$

Literature notes that the threshold for a “positive” Manning diagnosis **varies
from two to four** criteria (e.g. Saito *et al.*, *Am J Gastroenterol* 2000).
This package’s **default** `Is_Positive` uses

$$
T = 3 \quad \text{(i.e. } N \ge 3\text{)}
$$

documented as an educational midpoint within the published range — **not** a
clinical recommendation. Call `Meets_Threshold (C, T)` or
`Is_Positive (C, T)` for $T \in \{2,3,4\}$.

## Threshold discussion

| Threshold $T$ | Interpretation (educational) |
| --- | --- |
| $2$ | Most sensitive among common cutoffs; more false positives possible |
| $3$ | Default in this package; midpoint of published range |
| $4$ | Stricter; more specific / less sensitive |

Choice of $T$ affects case identification in epidemiological studies; see
Saito *et al.* (2000) comparing Rome and Manning for research case finding.
**This software does not advise which $T$ to use in practice.**

## Manning vs Rome (README note only)

The Manning list is a **fixed six-question symptom count**. Rome criteria
(Rome IV today for clinical research) use more structured time/frequency rules
and IBS subtypes (IBS-C, IBS-D, IBS-M, IBS-U). Comparisons (Fass *et al.* 2001;
Ford *et al.* 2013) show trade-offs in sensitivity and specificity. This package
implements **Manning only**; Rome is mentioned for pedagogical context and is
**not** encoded in Ada here.

## API (`Manning_Criteria`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Criteria`, `Criterion_Count` ($0$–$6$), `Threshold_Range` ($2$–$4$) | Inputs / counts |
| Constant | `Default_Threshold` ($= 3$) | Default for `Is_Positive` |
| Core | `Positive_Count`, `Meets_Threshold`, `Is_Positive` | Count and threshold checks |
| Helpers | `Pain_Linked_Contribution`, `Looser_Stools_Contribution`, `Pain_Relieved_Contribution`, `Bloating_Contribution`, `Incomplete_Evacuation_Contribution`, `Mucus_Diarrhea_Contribution` | $0$/$1$ contributions |
| Queries | `Has_Pain_Linked_To_More_Frequent_Stools`, `Has_Looser_Stools_With_Pain_Onset`, `Has_Pain_Relieved_By_Defecation`, `Has_Noticeable_Abdominal_Bloating`, `Has_Incomplete_Evacuation_GT_25_Pct`, `Has_Diarrhea_With_Mucus_GT_25_Pct` | Named field mirrors |

All functions are **pure** (`Global => null`); the package performs **no I/O**.

## Project layout

Exactly seven root files (no `main.adb`; `tests.adb` is the GPR main):

1. `manning_criteria.ads` — package specification
2. `manning_criteria.adb` — package body
3. `manning_criteria.gpr` — GNAT project (Main = `tests.adb`)
4. `Makefile` — `all` / `test` / `clean`
5. `tests.adb` — standalone test suite
6. `README.md` — this file
7. `.gitignore` — ignores `obj/` and `bin/`

## Build and test

Requires GNAT (Ada 2023 / `-gnat2022`).

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pmanning_criteria.gpr
make test                 # run bin/tests; expect Fail_Count=0
```

Flags: `-gnatwa -gnat2022`. Build should exit $0$ with zero warnings; tests should
exit $0$ with `Fail_Count=0` and at least $100$ `PASS` assertions (including the
full $2^{6} = 64$ combinatorial mask space).

## References (educational)

- [Wikipedia: Manning Criteria](https://en.wikipedia.org/wiki/Manning_Criteria)
- Manning AP, Thompson WG, Heaton KW, Morris AF. Towards positive diagnosis of
  the irritable bowel. *Br Med J.* 1978;2(6138):653–654. PMID 698649.
- Saito YA *et al.* A comparison of the Rome and Manning criteria for case
  identification… *Am J Gastroenterol.* 2000;95(10):2816–2824.
- Fass R *et al.* Evidence- and consensus-based practice guidelines for the
  diagnosis of IBS. *Arch Intern Med.* 2001;161(17):2081–2088.
- Ford AC *et al.* Validation of the Rome III criteria… *Gastroenterology.*
  2013;145(6):1262–1270.e1.

## License / intent

Provided for **education and software testing** of algorithm encodings.
**Not for clinical use.**
