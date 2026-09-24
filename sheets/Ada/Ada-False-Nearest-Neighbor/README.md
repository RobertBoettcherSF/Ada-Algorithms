# False Nearest Neighbor (FNN) — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: False nearest neighbor](https://en.wikipedia.org/wiki/False_nearest_neighbor)
algorithm for estimating the **delay-embedding dimension** of a scalar
time series. The Wikipedia page is a short stub; this package follows the
standard **Kennel–Brown–Abarbanel** geometrical criterion (1992), as
surveyed by Rhodes & Morari (1997).

Related ideas: [Takens' embedding theorem](https://en.wikipedia.org/wiki/Takens%27s_theorem),
phase-space reconstruction, and nonlinear time-series analysis.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Delay embedding** | $y_n=(x_n,x_{n+\tau},\ldots,x_{n+(m-1)\tau})$ | Valid $n$ only |
| **Nearest neighbour** | Brute-force Euclidean $R_m$ | Optional Theiler window $W$ |
| **False test (1)** | $\lvert x_{n+m\tau}-x_{n'+m\tau}\rvert / R_m > R_{\mathrm{tol}}$ | Typical $R_{\mathrm{tol}}\approx 10..15$ |
| **False test (2)** | $R_{m+1}/\sigma_x > A_{\mathrm{tol}}$ | Typical $A_{\mathrm{tol}}\approx 2$ |
| **Fraction** | $\mathrm{FNN}(m)=\#\mathrm{false}/\#\mathrm{tested}$ | Choose smallest $m$ near 0 |
| **Estimate** | First $m$ with $\mathrm{FNN}(m)\le$ threshold | Pedagogical default 10% |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Algorithm (Kennel et al. 1992)

Given scalar observations $x_1,\ldots,x_N$, delay $\tau\ge 1$, and trial
dimension $m\ge 1$, form delay vectors in $\mathbb{R}^m$. For each
reference $y_n$, find a nearest neighbour $y_{n'}$ ($n'\ne n$, and
optionally $\lvert n-n'\rvert > W$).

Lifting to dimension $m+1$ adds the coordinate $x_{n+m\tau}$. With
$R_{m+1}^2 = R_m^2 + (x_{n+m\tau}-x_{n'+m\tau})^2$, the neighbour is
**false** if either relative stretching (criterion 1) or absolute size
versus the series standard deviation $\sigma_x$ (criterion 2) exceeds
tolerance. The fraction of false neighbours should drop toward zero once
$m$ is large enough to unfold the attractor.

Brute-force search is intentional: suitable for educational series of a
few hundred points.

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Constants | `Max_Series`, `Max_Dim` | Capacity bounds |
| Types | `Real`, `Series`, `Fraction_Array`, `FNN_Config` | Domain model |
| Config | `Make_Config` | Defaults $R_{\mathrm{tol}}=15$, $A_{\mathrm{tol}}=2$ |
| Helpers | `Near`, `Mean`, `Std_Dev` | Numerics |
| Geometry | `Embedding_Distance_Sq`, `Nearest_Neighbor_Index` | Delay distances / NN |
| Criterion | `Is_False_Neighbor` | Kennel tests (1)+(2) |
| Stats | `False_Neighbor_Fraction`, `FNN_Profile` | $\mathrm{FNN}(m)$, profile |
| Estimate | `Estimate_Embedding_Dimension` | Smallest $m$ below threshold |

Strong typing uses `Real` (digits 12). Public subprograms carry `Pre` /
`Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Usage

```ada
with False_Nearest_Neighbor; use False_Nearest_Neighbor;

declare
   X   : constant Series := [...];  -- scalar observations
   Cfg : constant FNN_Config :=
     Make_Config (Tau => 4, R_Tol => 15.0, A_Tol => 2.0,
                  Theiler => 1, Max_Dim => 8);
   Prof : Fraction_Array (1 .. Cfg.Max_Dim);
   M_Hat : Natural;
begin
   Prof  := FNN_Profile (X, Cfg);
   M_Hat := Estimate_Embedding_Dimension (X, Cfg, Threshold => 0.10);
end;
```

## Layout

Root-only sources (no `src/`, no separate `main.adb`):

- `false_nearest_neighbor.ads` / `.adb` / `.gpr`
- `tests.adb`, `Makefile`, `README.md`, `.gitignore`

## Building

```bash
cd /workspace/ada-false-nearest-neighbor
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pfalse_nearest_neighbor.gpr`. Expect
**zero errors and zero warnings**.

## Testing

```bash
make test
```

The standalone `tests.adb` driver builds synthetic sine / circle / noise /
logistic / Hénon series in-process (no external data files), exercises
embedding distances, Theiler exclusion, tolerance edges, invalid inputs,
profiles, and embedding estimates. Success requires `Fail_Count = 0`
(`pragma Assert`).

## References

1. Kennel, M. B., Brown, R., & Abarbanel, H. D. I. (1992).
   *Determining embedding dimension for phase-space reconstruction using a
   geometrical construction.* Physical Review A, 45(6), 3403–3411.
   doi:10.1103/PhysRevA.45.3403
2. Rhodes, C., & Morari, M. (1997).
   *The false nearest neighbors algorithm: An overview.*
   Computers & Chemical Engineering, 21, S1149–S1154.
   doi:10.1016/S0098-1354(97)87657-0
3. Hegger, R., & Kantz, H. (1999).
   *Improved false nearest neighbor method to detect determinism in time
   series data.* Physical Review E, 60(4), 4970–4973.
   doi:10.1103/PhysRevE.60.4970
4. Takens, F. (1981). *Detecting strange attractors in turbulence.*
   In *Dynamical Systems and Turbulence*, Lecture Notes in Mathematics 898.
5. Wikipedia: [False nearest neighbor](https://en.wikipedia.org/wiki/False_nearest_neighbor)
   (algorithm stub; concept proposed by Kennel et al. 1992).

## License

Educational reference implementation for study and experimentation.
