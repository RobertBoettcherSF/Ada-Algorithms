# WACA Clustering — Ada 2023 (Weighted Application-aware Clustering)

Educational, self-contained Ada 2023 package for
[Wikipedia: WACA clustering algorithm](https://en.wikipedia.org/wiki/WACA_clustering_algorithm):
**WACA** (*Weighted Application-aware Clustering Algorithm*) for mobile
hybrid / ad-hoc networks
(Matthias R. Brust, Adrian Andronache, Steffen Rothkugel,
*ICWMC 2007*, [arXiv:0706.1080](https://arxiv.org/abs/0706.1080)).

Each device computes a local **weight** from device and topology attributes,
then elects as clusterhead the **1-hop neighbor (or itself) with highest
weight**. Following `ch` pointers yields a hierarchy of full clusterheads,
**sub-heads**, and **slaves**. A **king bonus** added to stable clusterheads
reduces needless re-elections under mobility.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

This is an **educational reconstruction** of paper §IV / Fig.1 (prefer paper
semantics over the Wikipedia stub). Formulas for dissemination degree use a
convenient score that peaks at the ideal degree.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Graph** | Undirected 1-hop neighbor lists | Unit-disk *or* explicit edges |
| **PA** | $\mathrm{PA}=\ln(1+P(d))$ | Log diminishing returns on power |
| **Signal** | $s(d)\in[0,1]$ | Backbone / cellular signal |
| **DD** | $1/(1+|deg-dd_I|)$ | Peaks at ideal degree (e.g. 7) |
| **$c_L$** | Edges among nbrs / $\binom{deg}{2}$ | 0 if $deg<2$ |
| **Weight** | $W=W_0+K$, $W_0=\sum w_i f_i$ | King bonus ($K\ge0$) |
| **Election** | Argmax weight in $N(d)\cup\{d\}$ | Ties → lowest device id |
| **Roles** | CH / Sub-Head / Slave | Paper Fig.1 `isClusterHead` / `isSubHead` |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Nodes`, `Device_Id`, `Node_Attrs` | Fixed educational limits |
| Graph | `Empty_Graph`, `Add_Undirected_Edge`, `Build_Unit_Disk` | Topology |
| Helpers | `Near`, `Degree` | Utilities |
| Components | `Power_Appropriateness`, `Dissemination_Degree_Score`, `Local_Clustering_Coefficient` | Weight parts |
| Weight | `Compute_Weight` | $W_0+K$ |
| Election | `Elect_Clusterheads`, `Run_WACA` | Fig.1 + roles |
| Hierarchy | `Follow_To_Root` | Walk CH pointers |
| Stability | `King_Bonus_Update`, `Stability_Coefficient` | Educational Fig.4 |

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formula summary

### Power, signal, dissemination, clustering

$$
\mathrm{PA}(d)=\ln\bigl(1+P(d)\bigr),\qquad
s(d)\in[0,1],
$$

$$
\mathrm{DD}(d)=\frac{1}{1+\bigl|\deg(d)-dd_I\bigr|},\qquad
c_L(d)=\begin{cases}
\dfrac{e(N(d))}{\deg(\deg-1)/2} & \deg\ge 2\\
0 & \text{otherwise}
\end{cases}
$$

where $e(N(d))$ is the number of edges among neighbors of $d$.

### Base weight and king bonus

$$
W_0(d)=wf_1\cdot\mathrm{PA}+wf_2\cdot s+wf_3\cdot\mathrm{DD}+wf_4\cdot c_L,
\qquad
W(d)=W_0(d)+K(d).
$$

Default factors (paper simulation style): $wf_1=0.9$, $wf_2=1$,
$wf_3=0.85$, $wf_4=0.65$. King bonus $K\in[0,99]$: on a stable
clusterhead neighborhood increase by 33 (cap 99); on churn reduce by
$K\cdot s$ with stability coefficient
$s=|M\Delta N|/(|M|+|N|)$; non-CH or isolated CH $\to K=0$.

### Election and hierarchy

Each device $d$ sets $ch(d)$ to $\arg\max_{x\in N(d)\cup\{d\}} W(x)$
(lowest id on ties). If $ch(d)=d$ then $d$ is a **clusterhead**; if some
neighbor elects $d$ but $d$ does not elect itself, $d$ is a **sub-head**;
otherwise a **slave**. `Follow_To_Root` walks $ch$ until a fixed point.

## Usage

```ada
with WACA_Clustering; use WACA_Clustering;

declare
   G : Graph := Empty_Graph (3);
   A : Attrs_Array (1 .. 3) :=
     (1 => (Power => 10.0, Signal => 0.2, Ideal_Degree => 7, King_Bonus => 0.0),
      2 => (Power => 20.0, Signal => 0.8, Ideal_Degree => 7, King_Bonus => 0.0),
      3 => (Power => 5.0,  Signal => 0.1, Ideal_Degree => 7, King_Bonus => 0.0));
   R : WACA_Result := Run_WACA (G, A);
begin
   Add_Undirected_Edge (G, 1, 2);
   Add_Undirected_Edge (G, 2, 3);
   R := Run_WACA (G, A);
   --  R.Role (D), R.Clusterhead_Of (D), R.Weights (D)
end;
```

Or build a unit-disk graph from positions:

```ada
Pos : constant Position_Array := [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)];
G   : constant Graph := Build_Unit_Disk (Pos, Range_R => 1.5);
```

## Building

```bash
make            # gnatmake -gnatwa -gnat2022 -Pwaca_clustering.gpr
make test       # build + run tests
make clean
```

Requires GNAT with Ada 2022 support. Root layout only (no `src/`).

## Testing

`tests.adb` is the sole main. It uses a local `Check` helper (no
`Ada.Assertions` for test logic) and ends with
`pragma Assert (Fail_Count = 0)`. Coverage includes PA monotonicity, DD peak,
triangle/star $c_L$, clique CH election, path sub-head chains, king-bonus
stability, empty/singleton graphs, invalid inputs, deterministic tie-break,
and role partition.

## Related work

- **WCA** (Chatterjee, Das, Turgut): weighted clustering for MANETs using
  degree, distances, speed, and battery — compared to WACA in the 2007 paper;
  WACA adds hierarchy (sub-heads), application-aware factors (backbone
  signal, dissemination degree, local clustering), and the king bonus.
- Injection communication / hybrid networks (backbone uplinks + ad-hoc).

## References

1. M. R. Brust, A. Andronache, S. Rothkugel, “WACA: A Hierarchical Weighted
   Clustering Algorithm Optimized for Mobile Hybrid Networks,” *ICWMC 2007*.
   [arXiv:0706.1080](https://arxiv.org/abs/0706.1080).
2. Wikipedia: [WACA clustering algorithm](https://en.wikipedia.org/wiki/WACA_clustering_algorithm).
3. M. Chatterjee, S. K. Das, D. Turgut, “WCA: A Weighted Clustering Algorithm
   for Mobile Ad Hoc Networks,” *Cluster Computing*, 2002.

## License

Educational / reference implementation. Not affiliated with the original
authors.
