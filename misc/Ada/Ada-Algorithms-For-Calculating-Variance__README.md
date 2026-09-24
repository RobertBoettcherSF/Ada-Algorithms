# Algorithms for Calculating Variance (Ada 2023)

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Algorithms for calculating variance](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance)
— numerically stable (and deliberately unstable) methods for population and
sample variance, including **Welford’s online algorithm**, **Chan parallel
merge**, **shifted-data**, **two-pass**, the **naïve Sum/SumSq** formula,
**West weighted incremental** updates, and **online co-moment covariance**.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Naïve** | One-pass $\sum x$, $\sum x^2$ | Numerically **unstable** |
| **Shifted** | Variance of $x_i-K$ | Location-invariant rewrite |
| **Two-pass** | Mean, then $\sum(x_i-\bar x)^2$ | Stable reference |
| **Welford** | Online $(n,\bar x,M_2)$ | Preferred single-pass |
| **Chan merge** | Combine two Welford states | Parallel / split reduce |
| **West weighted** | Incremental weighted $S$ | Frequency / reliability Bessel |
| **Covariance** | Online co-moment $C_n$ | Optional bivariate |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Real_Array`, `Welford_State` | Domain model |
| Welford | `Update`, `Update_Many`, `From_Array`, `Merge` | Online + parallel |
| Finish | `Sample_Variance`, `Population_Variance`, `Std_Dev` | $M_2/(n-1)$, $M_2/n$ |
| Arrays | `Naive_*`, `Shifted_*`, `Two_Pass_*` | Batch helpers |
| Weighted | `Weighted_State`, `Update_Weighted`, West variances | Optional |
| Covariance | `Covariance_State`, `Update_Covariance`, two-pass | Optional |
| Helpers | `Near`, `Sqrt_Nonneg`, `Two_Pass_Mean` | Numerics |

Strong typing uses domain types (`Real` digits 15, `Non_Negative`, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Empty_Sample`, `Degenerate`.

## Formula summary

### Population and sample variance

For a finite population of size $N$:

$$
\sigma^2 = \frac{1}{N}\sum_{i=1}^{N}(x_i-\bar x)^2
= \frac{\sum_{i=1}^{N}x_i^2}{N}-\left(\frac{\sum_{i=1}^{N}x_i}{N}\right)^2.
$$

With **Bessel’s correction** for a sample of size $n$:

$$
s^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i-\bar x)^2
= \left(\frac{\sum x_i^2}{n}-\bar x^2\right)\cdot\frac{n}{n-1}.
$$

Relation: $s^2=\sigma^2\cdot n/(n-1)$ when $\sigma^2$ denotes the $1/n$ moment
of the same finite set.

### Naïve one-pass (unstable)

Maintain $n$, $\mathrm{Sum}$, $\mathrm{SumSq}$. Then
$s^2=(\mathrm{SumSq}-(\mathrm{Sum}\cdot\mathrm{Sum})/n)/(n-1)$.
Catastrophic cancellation when the standard deviation is small relative to the
mean — **do not use in practice** (kept here for education / tests).

### Shifted data

$\operatorname{Var}(X-K)=\operatorname{Var}(X)$ for any constant $K$:

$$
s^2=\frac{\sum_{i=1}^{n}(x_i-K)^2-\bigl(\sum_{i=1}^{n}(x_i-K)\bigr)^2/n}{n-1}.
$$

Choosing $K$ near the mean (or any value in the sample range) restores
stability.

### Two-pass

First $\bar x=\frac{1}{n}\sum_j x_j$, then
$s^2=\frac{1}{n-1}\sum_i(x_i-\bar x)^2$.

### Welford online

Maintain count $n$, running mean $\bar x_n$, and second central moment
accumulator $M_2$:

$$
\bar x_n=\bar x_{n-1}+\frac{x_n-\bar x_{n-1}}{n},
$$

$$
M_{2,n}=M_{2,n-1}+(x_n-\bar x_{n-1})(x_n-\bar x_n).
$$

Then $s^2=M_2/(n-1)$ and population $\sigma^2=M_2/n$.

### Chan parallel merge

Combine accumulators $A$ and $B$:

$$
n_{AB}=n_A+n_B,\quad
\delta=\bar x_B-\bar x_A,
$$

$$
\bar x_{AB}=\frac{n_A\bar x_A+n_B\bar x_B}{n_{AB}},
$$

$$
M_{2,AB}=M_{2,A}+M_{2,B}+\delta^2\cdot\frac{n_A n_B}{n_{AB}}.
$$

### West weighted incremental

With weight $w$ for observation $x$:

$$
\bar x\leftarrow\bar x+\frac{w}{W}(x-\bar x_{\mathrm{old}}),\quad
S\leftarrow S+w(x-\bar x_{\mathrm{old}})(x-\bar x),
$$

where $W$ is the updated sum of weights. Population variance $S/W$;
frequency-weight sample $S/(W-1)$; reliability-weight sample
$S/(W-\sum w_i^2/W)$.

### Online covariance

Co-moment
$C_n=\sum_{i=1}^{n}(x_i-\bar x_n)(y_i-\bar y_n)$ updated as

$$
C_n=C_{n-1}+(x_n-\bar x_n)(y_n-\bar y_{n-1}),
$$

with sample covariance $C_n/(n-1)$.

## Usage

```ada
with Algorithms_For_Calculating_Variance;
use Algorithms_For_Calculating_Variance;

procedure Demo is
   Data : constant Real_Array :=
     (1 => 2.0, 2 => 4.0, 3 => 4.0, 4 => 4.0,
      5 => 5.0, 6 => 5.0, 7 => 7.0, 8 => 9.0);
   W : constant Welford_State := From_Array (Data);
begin
   --  Hand example: mean 5, sample variance 32/7, population 4
   pragma Assert (Near (Sample_Variance (W), 32.0 / 7.0));
end Demo;
```

Merge split streams:

```ada
Left  : constant Welford_State := From_Array (Data (1 .. Mid));
Right : constant Welford_State := From_Array (Data (Mid + 1 .. Data'Last));
All   : constant Welford_State := Merge (Left, Right);
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Palgorithms_for_calculating_variance.gpr`.
Main program is `tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `algorithms_for_calculating_variance.ads` | Package spec |
| `algorithms_for_calculating_variance.adb` | Package body |
| `algorithms_for_calculating_variance.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Standalone suite (custom `Check`, no `Ada.Assertions`) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## Testing

`tests.adb` uses a local `Check` helper (`Pass_Count` / `Fail_Count`) and ends
with `pragma Assert (Fail_Count = 0)`. Coverage includes:

- Hand example $[2,4,4,4,5,5,7,9]$ (mean $5$, $M_2=32$, $s^2=32/7$, $\sigma^2=4$)
- Bessel correction on $[1,2,3]$ and general $s^2=\sigma^2\cdot n/(n-1)$
- Welford ≡ two-pass ≡ shifted within tight tolerance
- Chan merge of splits ≡ full Welford (including empty identity)
- Naïve large-mean / small-spread case (stable methods OK; naïve degrades)
- Empty / $n=1$ edge exceptions
- West weighted equal- and unequal-weight cases
- Online covariance ≡ two-pass (correlated and anti-correlated)

## References

- Wikipedia: *Algorithms for calculating variance*
- Welford, B. P. (1962). *Note on a method for calculating corrected sums of squares and products*
- Chan, Golub, LeVeque — parallel / updating formulae for variance
- West, D. H. D. (1979). *Updating mean and variance estimates: an improved method*
- Pébay et al. — parallel / online higher-order moments and covariances
