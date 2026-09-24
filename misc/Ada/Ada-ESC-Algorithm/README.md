# ESC Algorithm (Heart Failure Pathway) — Ada 2023 Educational Encoding

> **NOT FOR CLINICAL USE.** This repository is an **educational / software-reference**
> encoding of commonly cited **European Society of Cardiology (ESC)** style
> heart-failure diagnostic pathway cutoffs (symptoms → natriuretic peptides →
> echocardiography / ejection-fraction phenotypes) for **unit testing** and
> algorithm pedagogy only. It is **not medical advice**, **not a medical device**,
> and **must not** guide diagnosis, triage, treatment, or patient counseling.
> Clinicians must follow **current guidelines**, local protocols, and clinical
> judgment. Thresholds **vary by guideline edition**, age, acuity (acute vs
> chronic), and assay — do **not** invent or rely on this software for patient care.

Educational, self-contained Ada 2023 package implementing a **simplified ESC-style
HF workup helper** as summarized on
[Wikipedia: Heart failure](https://en.wikipedia.org/wiki/Heart_failure)
(note: `https://en.wikipedia.org/wiki/ESC_algorithm` redirects there; the page
lists “ESC algorithm for the diagnosis of heart failure” among diagnostic
algorithms). The package exposes **deterministic** pure functions for symptom
gating, chronic natriuretic-peptide elevation checks, EF phenotype bands, and a
combined pathway result enum.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Critical disclaimer (read first)

- **Educational / software-reference only** — encodes published *rule-of-thumb*
  chronic cutoffs and EF phenotype bands for reproducible unit tests.
- **Not for clinical use** — not medical advice; not a substitute for history,
  examination, labs, imaging, or specialist evaluation.
- Documented educational cutoffs in this repo (chronic ambulatory style):
  - NT-proBNP $\ge 125$ pg/mL
  - BNP $\ge 35$ pg/mL
  - HFrEF: EF $\le 40\%$; HFmrEF: EF $41$–$49\%$; HFpEF: EF $\ge 50\%$
- **Acute**, **age-stratified**, and **edition-specific** thresholds differ and
  are **not** encoded. Choice of cutoff is a guideline/literature decision,
  **not** a recommendation from this software.

## ESC diagnostic idea (educational)

ESC-style chronic HF workup is often summarized as:

1. **Symptoms / signs** suggestive of heart failure (e.g. dyspnea, orthopnea,
   edema, fatigue).
2. If suggestive → measure **natriuretic peptides** (NT-proBNP or BNP).
3. If peptides are elevated (chronic educational cutoffs above) → proceed to
   **echocardiography**.
4. Classify by **left-ventricular ejection fraction (EF)** phenotype bands.

Wikipedia notes that ESC (and AHA/ACC/HFSA) recommend measuring NT-proBNP or BNP
followed by ultrasound of the heart if positive, in people with symptoms
consistent with heart failure. Diagnosis combines symptoms/signs with objective
evidence of cardiac structural or functional abnormality.

## Educational cutoffs encoded here

| Quantity | Educational constant | Value |
| --- | --- | --- |
| Chronic NT-proBNP “elevated” | `NT_proBNP_Chronic_Cutoff_Pg_Per_mL` | $125$ pg/mL |
| Chronic BNP “elevated” | `BNP_Chronic_Cutoff_Pg_Per_mL` | $35$ pg/mL |
| HFrEF upper EF | `EF_HFrEF_Max` | $40\%$ |
| HFmrEF band | `EF_HFmrEF_Min` .. `EF_HFmrEF_Max` | $41$–$49\%$ |
| HFpEF lower EF | `EF_HFpEF_Min` | $50\%$ |

Elevation predicates:

$$
\text{NT\_proBNP\_Elevated}(v) \iff v \ge 125
$$

$$
\text{BNP\_Elevated}(v) \iff v \ge 35
$$

EF phenotype:

$$
\text{Classify\_EF}(e) =
\begin{cases}
\text{HFrEF}  & e \le 40 \\
\text{HFmrEF} & 41 \le e \le 49 \\
\text{HFpEF}  & e \ge 50
\end{cases}
$$

## Pathway result logic (explicit)

`Evaluate_Pathway (W)` returns:

| Result | Educational meaning |
| --- | --- |
| `Unlikely` | No suggestive symptoms, **or** symptoms with measured NP below educational chronic cutoffs |
| `Incomplete_Data` | Suggestive symptoms but **no** NP measured |
| `Consider_Echo` | Symptoms + NP elevated, EF not yet available |
| `HF_Reduced` | Symptoms + NP elevated + EF $\le 40$ (HFrEF) |
| `HF_Mildly_Reduced` | Symptoms + NP elevated + EF $41$–$49$ (HFmrEF) |
| `HF_Preserved` | Symptoms + NP elevated + EF $\ge 50$ (HFpEF) |

`Natriuretic_Gate_Positive` is true if **any measured** peptide meets its cutoff;
unmeasured sides are ignored. Measuring neither peptide yields gate `False`
(and the pathway returns `Incomplete_Data` when symptoms are present).

## Related ESC work: HFA-PEFF (not fully encoded)

Wikipedia’s Algorithms section describes **HFA-PEFF**, an ESC/HFA score-based
algorithm for diagnosing **HFpEF** (major/minor domains across functional,
morphological, and biomarker findings). That multi-domain scorer is **not**
implemented in this package — only the simpler chronic NP + EF pathway helpers
above — to keep the educational encoding honest and small. See Pieske *et al.*,
*Eur Heart J* 2019 (HFA-PEFF consensus) for the full algorithm.

## API (`ESC_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Constants | `NT_proBNP_Chronic_Cutoff_Pg_Per_mL` ($125$), `BNP_Chronic_Cutoff_Pg_Per_mL` ($35$), `EF_HFrEF_Max` / `EF_HFmrEF_*` / `EF_HFpEF_Min` | Documented educational cutoffs |
| Types | `Symptom_Flags`, `Peptide_Panel`, `Workup`, `Phenotype`, `Pathway_Result`, `EF_Percent`, `Peptide_Pg_Per_mL` | Inputs / outcomes |
| Symptoms | `Has_Suggestive_Symptoms`, `Symptom_Count`, `Has_Dyspnea`, `Has_Orthopnea`, `Has_Edema`, `Has_Fatigue` | Symptom gate |
| Peptides | `NT_proBNP_Elevated`, `BNP_Elevated`, `Any_Peptide_Measured`, `Natriuretic_Gate_Positive` | NP gate |
| EF | `Classify_EF`, `Phenotype_To_Pathway` | Phenotype bands |
| Pathway | `Evaluate_Pathway` | Combined educational result |

All functions are **pure** (`Global => null`); the package performs **no I/O**.

## Project layout

Exactly seven root files (no `main.adb`; `tests.adb` is the GPR main):

1. `esc_algorithm.ads` — package specification
2. `esc_algorithm.adb` — package body
3. `esc_algorithm.gpr` — GNAT project (Main = `tests.adb`)
4. `Makefile` — `all` / `test` / `clean`
5. `tests.adb` — standalone test suite
6. `README.md` — this file
7. `.gitignore` — ignores `obj/` and `bin/`

## Build and test

Requires GNAT (Ada 2023 / `-gnat2022`).

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pesc_algorithm.gpr
make test                 # run bin/tests; expect Fail_Count=0
```

Flags: `-gnatwa -gnat2022`. Build should exit $0$ with zero warnings; tests should
exit $0$ with `Fail_Count=0` and at least $100$ `PASS` assertions (symptom
combinatorics, NP/EF boundaries, pathway outcomes, incomplete data, phenotype
exhaustiveness samples).

## References (educational)

- [Wikipedia: Heart failure](https://en.wikipedia.org/wiki/Heart_failure)
  (`ESC_algorithm` redirect target; Algorithms / diagnosis sections)
- [Wikipedia: Heart failure with preserved ejection fraction](https://en.wikipedia.org/wiki/Heart_failure_with_preserved_ejection_fraction)
- ESC Guidelines for the diagnosis and treatment of acute and chronic heart
  failure (educational context for chronic NP rule-out style cutoffs and EF
  phenotypes; edition-specific tables supersede this software)
- Pieske B *et al.* How to diagnose heart failure with preserved ejection
  fraction: the HFA-PEFF diagnostic algorithm. *Eur Heart J.* 2019
  (related ESC/HFA work — **not** encoded here)

---

**Again: not for clinical use.** Educational encoding of published rule-of-thumb
cutoffs for software testing only.
