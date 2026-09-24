# Pulmonary Embolism Diagnostic Algorithms — Ada 2023 (Educational Survey)

> **NOT FOR CLINICAL USE.** This repository is an **educational / software-reference**
> encoding of **published** pretest scoring rules (Wells PE, Revised Geneva, PERC)
> for **unit testing** and algorithm pedagogy only. It is **not medical advice**,
> **not a medical device**, and **must not** guide diagnosis, triage, imaging, or
> treatment. Clinicians must follow **current guidelines**, local protocols, and
> clinical judgment. Do not invent or rely on thresholds beyond the well-known
> published cutoffs documented below.

Educational, self-contained Ada 2023 **survey** package for pulmonary embolism
(PE) **diagnostic algorithms** as commonly summarized on
[Wikipedia: Pulmonary embolism](https://en.wikipedia.org/wiki/Pulmonary_embolism#Algorithms)
and related pages
([Geneva score](https://en.wikipedia.org/wiki/Geneva_score),
[Wells' score for pulmonary embolism](https://en.wikipedia.org/wiki/Wells%27_score_for_pulmonary_embolism),
PERC literature). The package implements **deterministic** pure functions that
add published criterion weights and map totals to published risk tiers.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Educational context (typical PE workup — not advice)

In emergency and inpatient settings, clinicians often estimate **pretest
probability** of PE before choosing D-dimer testing versus definitive imaging
(CT pulmonary angiography or V/Q). Structured scores such as **Wells** and
**Revised Geneva** formalize that estimate; the **PERC** rule is a separate
**rule-out** checklist used only when gestalt pretest probability is already
**low**. This package encodes the **arithmetic** of those published tables so
software tests can verify point math — it does **not** implement pathways,
D-dimer cutoffs, age-adjusted dimers, YEARS, or imaging decisions.

## Project overview

| Rule | Role (educational) | Output |
| --- | --- | --- |
| **Wells PE (classic)** | Weighted 7 criteria; half-points | Score $0$–$12.5$; 3-tier / 2-tier |
| **Simplified Wells** | 1 point per criterion | Score $0$–$7$; unlikely if $\le 1$ |
| **Revised Geneva (2006)** | Weighted clinical + HR bands | Score $0$–$22$; low / intermediate / high |
| **PERC** | 8 all-or-nothing protective criteria | All-negative vs positive count |

## Wells score (PE)

Classic weighted criteria (Wells *et al.*, *Thromb Haemost* 2000; widely
reproduced):

| Criterion | Points |
| --- | ---: |
| Clinical signs / symptoms of DVT | $3.0$ |
| PE is #1 diagnosis or equally likely | $3.0$ |
| Heart rate $> 100$ | $1.5$ |
| Immobilization $\ge 3$ days or surgery in prior 4 weeks | $1.5$ |
| Previous DVT / PE | $1.5$ |
| Hemoptysis | $1.0$ |
| Malignancy (treatment, recent, or palliative) | $1.0$ |

**Three-tier** (traditional): Low if score $< 2$; Moderate if $2$–$6$; High if
$> 6$.

**Two-tier / modified** (common Christopher-style cutoff): **Unlikely** if
score $\le 4$; **Likely** if score $> 4$.

**Simplified Wells**: each present criterion contributes $1$ point; **Unlikely**
if total $\le 1$; **Likely** if $> 1$.

This package documents and implements **both** the three-tier and two-tier
mappings on the classic weighted total, plus simplified Wells.

## Revised Geneva score (2006)

| Variable | Points |
| --- | ---: |
| Age $\ge 65$ years | $1$ |
| Previous DVT or PE | $3$ |
| Surgery or fracture within 1 month | $2$ |
| Active malignant condition | $2$ |
| Unilateral lower-limb pain | $3$ |
| Hemoptysis | $2$ |
| Heart rate $75$–$94$ bpm | $3$ |
| Heart rate $\ge 95$ bpm | $5$ |
| Pain on deep palpation of lower limb **and** unilateral edema | $4$ |

Heart-rate bands are **mutually exclusive** (not additive): $\ge 95$ yields $5$,
not $3+5$.

**Tiers** (Le Gal *et al.*, *Ann Intern Med* 2006): Low $0$–$3$; Intermediate
$4$–$10$; High $\ge 11$.

(Simplified Geneva and pregnancy-adapted Geneva are **not** implemented here;
see Wikipedia Geneva score for those variants.)

## PERC (Pulmonary Embolism Rule-out Criteria)

Kline *et al.* eight criteria. **PERC-negative** (rule-out *candidate* only in
an already low-risk setting — **not** encoded as clinical clearance) requires
**all** of:

- Age $< 50$
- Heart rate $< 100$
- Oxygen saturation $\ge 95\%$ (room air)
- No hemoptysis
- No estrogen use
- No prior DVT / PE
- No unilateral leg swelling
- No surgery / trauma requiring hospitalization in prior 4 weeks

Any failed protective condition makes PERC **positive** (further testing
consideration in clinical pathways — again, not advice from this software).

## API (`Pulmonary_Embolism_Algorithms`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Wells_Points`, `Geneva_Points`, `Wells_Criteria`, `Geneva_Criteria`, `PERC_Criteria` | Inputs / scores |
| Enums | `Wells_Three_Tier`, `Wells_Two_Tier`, `Simplified_Wells_Tier`, `Geneva_Tier` | Categories |
| Wells | `Wells_Score`, `Wells_Category_Three_Tier`, `Wells_Category_Two_Tier` | Classic score / tiers |
| Simplified | `Simplified_Wells_Score`, `Simplified_Wells_Category` | 1-point variant |
| Geneva | `Geneva_Score`, `Geneva_Category`, `Geneva_Age_Points`, `Geneva_HR_Points` | Revised Geneva |
| PERC | `PERC_All_Negative`, `PERC_Positive_Count`, `PERC_Is_Positive`, `PERC_Age_OK`, `PERC_Heart_Rate_OK`, `PERC_Oxygen_OK` | Rule-out checklist |
| Helper | `Educational_Wells_Unlikely_And_PERC_Negative` | Two-tier Unlikely **and** PERC-negative (pedagogy only) |
| Points | `Wells_*_Points` helpers | Transparent criterion weights |

All scoring entry points are **pure** (`Global => null`); no I/O.

## Build and test

```bash
make clean && make
make test
```

- Compiler: `gnatmake -gnatwa -gnat2022`
- GPR main: `tests.adb`
- Expect: build exit $0$ with zero `-gnatwa` warnings; tests exit $0$,
  `Fail_Count=0`, at least $100$ `PASS` lines (includes full $2^8=256$ PERC
  mask consistency check).

## Layout

Exactly seven root files (no `main.adb`):

1. `pulmonary_embolism_algorithms.ads`
2. `pulmonary_embolism_algorithms.adb`
3. `pulmonary_embolism_algorithms.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/` `bin/`)

## References (public)

- [Wikipedia: Pulmonary embolism — Algorithms](https://en.wikipedia.org/wiki/Pulmonary_embolism#Algorithms)
- [Wikipedia: Geneva score](https://en.wikipedia.org/wiki/Geneva_score)
- [Wikipedia: Wells' score for pulmonary embolism](https://en.wikipedia.org/wiki/Wells%27_score_for_pulmonary_embolism)
- Wells PS *et al.*, *Thromb Haemost* 2000 — derivation / D-dimer utility
- Le Gal G *et al.*, *Ann Intern Med* 2006 — revised Geneva score
- Kline JA *et al.*, *J Thromb Haemost* 2004 / 2008 — PERC derivation and prospective evaluation

## Disclaimer (repeat)

**Educational software only.** Not for clinical use. Not medical advice. Point
values and cutoffs are those **commonly published** for these named scores; local
guideline versions may differ. Always defer to licensed clinicians and current
society guidelines.
