# Random Sample Consensus — RANSAC (Ada 2023)

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Random sample consensus](https://en.wikipedia.org/wiki/Random_sample_consensus)
(**RANSAC**) as introduced by **Fischler & Bolles (1981)**.

RANSAC is an iterative robust estimator for model parameters from data that
contain **outliers**. It repeatedly draws a **minimal random sample**, fits a
hypothesis model, counts the **consensus set** (inliers within a distance
threshold $t$), and keeps the best consensus — optionally **refitting** on
all inliers. Unlike ordinary least squares, gross outliers do not pull the
final model when a pure-inlier sample is found.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **2-D line** | $ax+by+c=0$ normalized | Wikipedia primary example; sample size $n=2$ |
| **2-D circle** | center + radius | Minimal sample $n=3$ non-collinear |
| **Baseline LS** | Covariance / PCA line; Kåsa circle | Fragile contrast vs RANSAC |
| **Iteration cap** | $N=\lceil\log(1-p)/\log(1-w^s)\rceil$ | Wikipedia adaptive $k$ |
| **MSAC-lite** | $\sum\min(d_i^2,t^2)$ | Torr & Zisserman–inspired score |
| **Determinism** | Seeded xorshift32 `Seeded_RNG` | Same seed ⇒ same result |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms | Role |
| --- | --- | --- |
| Geometry | `Point2`, `Line2`, `Circle2`, `Dist2`, `Normalize_Line` | Domain types |
| Line fit | `Fit_Line_From_Two_Points`, `Fit_Line_Least_Squares` | Minimal / LS |
| Circle fit | `Fit_Circle_From_Three_Points`, masked Kåsa LS | Minimal / LS |
| Consensus | `Point_Line_Distance`, `Count_Line_Inliers`, `Collect_*` | Threshold $t$ |
| Score | `Line_MSAC_Score`, `Circle_MSAC_Score` | MSAC-lite |
| Iterations | `Estimate_Iterations` | Wikipedia $N(w,s,p)$ |
| Drivers | `RANSAC_Fit_Line`, `RANSAC_Fit_Circle` | Full loop + optional refit |
| Config | `Make_Config`, `RANSAC_Config` | $N,t,d,p$, seed, flags |
| RNG | `Make_RNG`, `Next_Natural`, `Next_Index` | Reproducible sampling |

Strong typing uses domain types (`Real` digits 12, bounded `Point_Array`,
`Inlier_Mask`, result records). Public subprograms carry `Pre` / `Post` /
`Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`, `Did_Not_Converge` (available for extensions).

## Algorithm (Wikipedia overview)

1. Draw a random minimal subset (**hypothetical inliers**).
2. Fit a model to that subset only.
3. Test all data against the model; points within threshold $t$ form the
   **consensus set**.
4. If the consensus is large enough ($> d$), optionally refit on all
   inliers and record the score.
5. Repeat up to $k$ iterations; return the best model.

### Parameters

| Symbol | Config field | Meaning |
| --- | --- | --- |
| $t$ | `Distance_Threshold` | Max inlier residual |
| $k$ / $N$ | `Max_Iterations` | Iteration budget |
| $d$ | `Min_Inliers` | Minimum consensus size |
| $p$ | `Confidence` | Desired success probability |
| — | `Seed` | Deterministic RNG seed |
| — | `Refit_On_Inliers` | Final LS on consensus |
| — | `Use_MSAC_Score` | Truncated squared-error score |
| — | `Adaptive_Stop` | Shrink $k$ from current inlier ratio |

Wikipedia iteration estimate:

$$
k = \frac{\log(1-p)}{\log(1-w^{s})}
$$

where $w$ is the inlier fraction and $s$ is the minimal sample size.

## MSAC / MLESAC (related, not full deps)

**MSAC** (M-estimator Sample and Consensus) and **MLESAC** (Maximum Likelihood
Estimation SAmple and Consensus) replace pure inlier **cardinality** with a
likelihood / truncated residual quality measure (Torr & Zisserman). This package
implements an **MSAC-lite** score $\sum_i \min(d_i^2, t^2)$ used as a
tie-break / ranking aid; it does not implement full MLESAC mixture likelihoods,
PROSAC, or R-RANSAC.

## Usage

```bash
cd /workspace/ada-ransac
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

```ada
Cfg : constant RANSAC_Config :=
  Make_Config (Max_Iterations => 200,
               Distance_Threshold => 0.5,
               Seed => 42,
               Refit_On_Inliers => True);
Res : constant RANSAC_Line_Result := RANSAC_Fit_Line (Points, Cfg);
--  Res.Model, Res.Inlier_Count, Res.Inliers, Res.Score
```

## Testing

`make test` runs a rich standalone suite (≥13 sections, 90+ assertions):
two-point / LS line geometry, outlier corruption vs RANSAC recovery, inlier
thresholds, iteration-estimate edge cases ($w=1$, $w\approx 0$), seeded
reproducibility, degenerate samples, adaptive config, circle RANSAC on a
noisy ring with outliers, MSAC ranking, and refit stability.

## Building

Requires GNAT with Ada 2022 support. Flags: `-gnatwa -gnat2022` via
`-Pransac.gpr`. Zero warnings expected.

## References

- Martin A. Fischler & Robert C. Bolles, *Random Sample Consensus: A Paradigm
  for Model Fitting with Applications to Image Analysis and Automated
  Cartography*, Comm. ACM 24(6):381–395, June 1981.
- Wikipedia: *Random sample consensus* (pseudocode, parameters, MSAC/MLESAC).
- P.H.S. Torr & A. Zisserman, *MLESAC: A new robust estimator…*, CVIU 78, 2000.
- Richard Hartley & Andrew Zisserman, *Multiple View Geometry in Computer
  Vision*, 2nd ed., Cambridge, 2003.

## Related Ada packages

Sibling educational Ada 2023 algorithm packages under `/workspace/ada-*`
(scoring algorithm, Yamartino method, clipping, etc.) share the same layout
conventions (`*.ads`/`*.adb` at repo root, `tests.adb` as main, `-gnatwa
-gnat2022`).
