# Kalman Filter (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter)
(**linear quadratic estimation**) — a recursive estimator for the state of a
**discrete-time linear dynamical system** observed in **Gaussian** noise.

Named after [Rudolf E. Kálmán](https://en.wikipedia.org/wiki/Rudolf_E._K%C3%A1lm%C3%A1n)
(1960). The filter alternates a **Predict** phase (propagate mean and covariance
with the state-transition model) and an **Update** phase (assimilate a
measurement with the optimal Kalman gain).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Predict** | $\hat x_{k\mid k-1}=F\hat x+Bu$, $P_{k\mid k-1}=FPF^\mathsf{T}+Q$ | Wikipedia discrete KF |
| **Update** | innovation $\tilde y=z-H\hat x$, gain $K=PH^\mathsf{T}S^{-1}$ | $S=HPH^\mathsf{T}+R$ |
| **Joseph form** | $P\leftarrow(I-KH)P(I-KH)^\mathsf{T}+KRK^\mathsf{T}$ | Prefer numerically |
| **Scalar KF** | 1-D state & measurement | Clearest educational core |
| **Vector KF** | Dense matrices, `Max_Dim = 4` | Small fixed dimension |
| **Solve** | Gaussian elimination + partial pivot | For $S^{-1}$ / gain |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Helpers | `Near`, `Identity`, `Zero_Vector`, `Zero_Matrix` | Numerics |
| Linear algebra | `Transpose`, `+`, `-`, `*`, `Scale`, `Solve`, `Invert` | Dense ops |
| Scalar | `Scalar_State`, `Scalar_Predict`, `Scalar_Update`, `Scalar_Step` | 1-D KF |
| Vector | `Filter_State`, `Model`, `Predict`, `Update`, `Filter_Step` | N≤4 KF |

Strong typing uses domain types (`Real` digits 12, `Vector`, `Matrix`, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formula summary (Wikipedia discrete KF)

**Predict**

$$
\hat{\mathbf{x}}_{k\mid k-1}
=
\mathbf{F}_k\hat{\mathbf{x}}_{k-1\mid k-1}+\mathbf{B}_k\mathbf{u}_k,
\qquad
\mathbf{P}_{k\mid k-1}
=
\mathbf{F}_k\mathbf{P}_{k-1\mid k-1}\mathbf{F}_k^\mathsf{T}+\mathbf{Q}_k.
$$

**Update**

$$
\begin{aligned}
\tilde{\mathbf{y}}_k
&=
\mathbf{z}_k-\mathbf{H}_k\hat{\mathbf{x}}_{k\mid k-1},\\
\mathbf{S}_k
&=
\mathbf{H}_k\mathbf{P}_{k\mid k-1}\mathbf{H}_k^\mathsf{T}+\mathbf{R}_k,\\
\mathbf{K}_k
&=
\mathbf{P}_{k\mid k-1}\mathbf{H}_k^\mathsf{T}\mathbf{S}_k^{-1},\\
\hat{\mathbf{x}}_{k\mid k}
&=
\hat{\mathbf{x}}_{k\mid k-1}+\mathbf{K}_k\tilde{\mathbf{y}}_k,\\
\mathbf{P}_{k\mid k}
&=
(\mathbf{I}-\mathbf{K}_k\mathbf{H}_k)\mathbf{P}_{k\mid k-1}
(\mathbf{I}-\mathbf{K}_k\mathbf{H}_k)^\mathsf{T}
+
\mathbf{K}_k\mathbf{R}_k\mathbf{K}_k^\mathsf{T}
\quad\text{(Joseph form)}.
\end{aligned}
$$

### Scalar vs vector

- **Scalar** (`Scalar_*`): educational special case with state $x\in\mathbb{R}$
  and variance $P\ge 0$. Joseph update reduces to
  $P\leftarrow(1-KH)^2 P + K^2 R$.
- **Vector** (`Predict` / `Update` / `Filter_Step`): dense `Max_Dim = 4`
  matrices; `Model` holds $F,H,Q,R$ and optional control $B$.

### Joseph form

The “usual” update $P\leftarrow(I-KH)P$ can lose symmetry / positivity to
round-off. The **Joseph form** used here is algebraically equivalent for the
optimal gain and is preferred in practice for numerical stability.

## Usage

```ada
with Kalman_Filter; use Kalman_Filter;

--  Scalar
declare
   S : Scalar_State := (X => 0.0, P => 1.0);
   Y, K : Real;
begin
   Scalar_Step (S, F => 1.0, B => 0.0, U => 0.0, Q => 0.01,
                Z => 2.5, H => 1.0, R => 0.5,
                Innovation => Y, Gain => K);
end;

--  Vector (2-D constant-velocity lite)
declare
   St  : Filter_State (N => 2);
   Mdl : Model (N => 2, M => 1);
   Z   : Vector (1 .. 1) := (1 => 1.0);
   Inn : Vector (1 .. 1);
   G   : Matrix (1 .. 2, 1 .. 1);
begin
   Mdl.F := ((1.0, 1.0), (0.0, 1.0));
   Mdl.H := (1 => (1.0, 0.0));
   Mdl.Q := ((0.01, 0.0), (0.0, 0.01));
   Mdl.R := (1 => (1 => 0.25));
   St.X := (0.0, 0.0);
   St.P := Identity (2);
   Filter_Step (St, Mdl, Z, Inn, G);
end;
```

## Building

```bash
cd /workspace/ada-kalman-filter
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pkalman_filter.gpr`. Expect **zero**
errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (standalone main). The suite covers scalar predict/update
hand checks, Joseph non-negativity, convergence under noise, $R\to 0$,
static variance decrease, singular edges, 2-D models, and multi-step RMSE
versus raw measurements. Ends with `pragma Assert (Fail_Count = 0)`.

## Related (notes only — not implemented)

- **Extended Kalman filter (EKF):** linearize nonlinear $f,h$ with Jacobians
  at the current estimate; same predict/update structure on the tangent model.
- **Unscented Kalman filter (UKF):** propagate sigma points through nonlinear
  maps; avoid explicit Jacobians.
- Continuous-time **Kalman–Bucy** filter; information / square-root forms.

This package deliberately stays with the **discrete linear Gaussian** Wikipedia
core (scalar + small dense vector + Joseph update).

## Layout

```
kalman_filter.ads / .adb / .gpr
Makefile  tests.adb  README.md  .gitignore
```

Root-only sources (no `src/`, no separate `main.adb`).
