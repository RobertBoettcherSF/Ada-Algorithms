# Vincenty's Formulae — Ada 2023

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Vincenty's formulae](https://en.wikipedia.org/wiki/Vincenty's_formulae)
— **Thaddeus Vincenty**'s compact iterative methods (*Survey Review* XXIII,
176, April **1975**) for **direct** and **inverse** geodesics on an
**oblate spheroid**.

They map the ellipsoidal geodesic to a great circle on an auxiliary sphere
(Legendre / Bessel / Helmert / Rainsford) and evaluate truncated nested
series to $O(f^{3})$. On the Earth ellipsoid they are typically accurate to
about **0.5 mm**, far better than spherical **great-circle** / **haversine**
methods that ignore flattening.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Figure** | Oblate spheroid $(a,f)$, $b=a(1-f)$ | Default **WGS-84** |
| **Inverse** | Iterate $\lambda$ until convergence | $s$, $\alpha_{1}$, $\alpha_{2}$ |
| **Direct** | Iterate $\sigma$ from $s/(bA)$ | $(\varphi_{2},L_{2})$, $\alpha_{2}$ |
| **Sphere** | Optional haversine helper | Short-arc comparison |
| **Failure** | Near-antipodes may not converge | `Converged` status flag |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Ellipsoid`, `Inverse_Result`, `Direct_Result` | Domain model |
| Ellipsoid | `WGS84`, `Semi_Minor`, `WGS84_A`, `WGS84_F` | $a$, $f$, $b$ |
| Inverse | `Inverse`, `Inverse_Degrees` | $(\varphi_{1},L_{1}),(\varphi_{2},L_{2})\to s,\alpha$ |
| Direct | `Direct`, `Direct_Degrees` | $\varphi_{1},L_{1},\alpha_{1},s\to$ end point |
| Sphere | `Haversine`, `Haversine_Degrees` | Great-circle comparison |
| Helpers | `Near`, `Deg_To_Rad`, `Rad_To_Deg`, `Normalize_Longitude` | Numerics |

`Real` is `digits 15` (Long_Float-class) for geodesy. Results carry
`Converged` and `Iterations`. Named exception: `Invalid_Argument`.

## Formula summary (Vincenty 1975)

### Ellipsoid

Semi-major $a$, flattening $f$, semi-minor

$$
b = a\,(1 - f).
$$

**WGS-84** defaults: $a = 6378137\,\mathrm{m}$,
$f = 1/298.257223563$, so $b \approx 6356752.314245\,\mathrm{m}$.

Reduced latitudes:

$$
U_{1} = \arctan\bigl((1-f)\tan\varphi_{1}\bigr),\quad
U_{2} = \arctan\bigl((1-f)\tan\varphi_{2}\bigr).
$$

### Inverse problem

Given $(\varphi_{1},L_{1})$ and $(\varphi_{2},L_{2})$, set $L = L_{2}-L_{1}$
and iterate $\lambda$ (starting from $\lambda = L$) using

$$
\sin\sigma =
\sqrt{(\cos U_{2}\sin\lambda)^{2}
+(\cos U_{1}\sin U_{2}-\sin U_{1}\cos U_{2}\cos\lambda)^{2}},
$$

$$
\cos\sigma = \sin U_{1}\sin U_{2}+\cos U_{1}\cos U_{2}\cos\lambda,
\quad
\sigma = \operatorname{atan2}(\sin\sigma,\cos\sigma),
$$

then update $\lambda$ with the nested $C$-series until
$|\Delta\lambda| \le 10^{-12}$ (about $0.006\,\mathrm{mm}$). Finally

$$
s = b\,A\,(\sigma - \Delta\sigma)
$$

with nested $A,B$ in $u^{2}=\cos^{2}\alpha\,(a^{2}-b^{2})/b^{2}$, and
azimuths $\alpha_{1},\alpha_{2}$ via $\operatorname{atan2}$.

**Near-antipodal** pairs may fail to converge (Wikipedia: first $\lambda$
guess with $|\lambda|>\pi$). This package returns `Converged => False`
rather than looping forever.

### Direct problem

Given $(\varphi_{1},L_{1})$, forward azimuth $\alpha_{1}$, and distance $s$,
form $U_{1}$, $\sigma_{1}$, $\sin\alpha$, series $A,B$, then iterate

$$
\sigma = \frac{s}{bA} + \Delta\sigma
$$

until $\sigma$ is stable, and recover $(\varphi_{2},L_{2})$ and $\alpha_{2}$.

### Spherical comparison (haversine)

On a sphere of radius $R$,

$$
\operatorname{hav}(\theta) = \sin^{2}(\theta/2),\quad
d = 2R\arcsin\sqrt{\operatorname{hav}(\Delta\varphi)
+\cos\varphi_{1}\cos\varphi_{2}\operatorname{hav}(\Delta L)}.
$$

Useful for short baselines; ignore flattening.

## API sketch

```ada
E : constant Ellipsoid := WGS84;
R : Inverse_Result :=
  Inverse_Degrees (48.137, 11.575, 52.52, 13.405, E);
-- R.Distance (m), R.Azimuth1 / R.Azimuth2 (rad), R.Converged

D : Direct_Result :=
  Direct_Degrees (48.137, 11.575, 0.0, 50_000.0);
-- D.Lat2, D.Lon2, D.Azimuth2 (radians)
```

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with project `vincenty.gpr`
(`Main = tests.adb`). Expect **exit 0**, zero warnings, `Fail_Count=0`,
and **≥100 PASS**.

## Accuracy note

Away from near-antipodes, Vincenty's truncated series are accurate to
roughly half a millimetre on WGS-84. For a complete, faster inverse on all
inputs (including antipodes), see Karney (2013) / GeographicLib — not
implemented here.

## References

- Thaddeus Vincenty, *Direct and Inverse Solutions of Geodesics on the
  Ellipsoid with application of nested equations*, Survey Review, 1975.
- [Vincenty's formulae (Wikipedia)](https://en.wikipedia.org/wiki/Vincenty's_formulae)
- WGS-84 ellipsoid parameters; haversine / great-circle distance for sphere.

## License

Educational reference implementation for the Ada algorithm series.
