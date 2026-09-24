# Chakravala method — Ada 2023

Educational, self-contained Ada 2023 package for the **chakravala**
(cyclic) method that solves **Pell's equation**

$$x^{2}-ny^{2}=1$$

for nonsquare positive integers $n$. The algorithm builds a sequence of
auxiliary triples $(a,b,k)$ with $a^{2}-nb^{2}=k$ by composing with
trivial triples $(m,1,m^{2}-n)$ (Brahmagupta–Bhāskara identity) and
scaling via Bhāskara's lemma until $k=\pm 1$; when $k=-1$ one
self-composition yields $k=1$. See
[Wikipedia: Chakravala method](https://en.wikipedia.org/wiki/Chakravala_method).

This package is a **classroom sketch** on `Long_Integer` (signed 64-bit
on typical GNAT). Famous classroom demos that fit include $n=2$
($(x,y)=(3,2)$), $n=13$ ($(649,180)$), and Bhāskara's $n=61$
($(1766319049,226153980)$). It is **not** a production big-integer Pell
solver — some $n\le\texttt{Max\_N}$ may still overflow intermediates.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Related / sibling rows (README links only — **no** package `with`):

- **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** —
  gcd / Bézout building block
- **[Ada-Dixon](https://github.com/RobertBoettcherSF/Ada-Dixon)** —
  factorization (congruence of squares)
- **[Ada-Integer-Factorization](https://github.com/RobertBoettcherSF/Ada-Integer-Factorization)** —
  factorization survey

## Method sketch

From Brahmagupta's identity, two solutions of $x^{2}-Ny^{2}=k$ compose:

$$(x_{1}x_{2}+Ny_{1}y_{2})^{2}-N(x_{1}y_{2}+x_{2}y_{1})^{2}=(x_{1}^{2}-Ny_{1}^{2})(x_{2}^{2}-Ny_{2}^{2}).$$

Composing $(a,b,k)$ with $(m,1,m^{2}-N)$ and dividing by $|k|$ (when
$m$ is chosen so that $(a+bm)/k$ is an integer, minimizing $|m^{2}-N|$)
is one chakravala step. Repeat until $k=1$.

## API sketch

| Operation | Role |
| --- | --- |
| `Is_Perfect_Square` / `Floor_Sqrt` | Square tests / integer $\sqrt{\cdot}$ |
| `Compose` | Brahmagupta–Bhāskara identity |
| `Initial_Triple` / `Choose_M` / `Chakravala_Step_From` | One cyclic step |
| `Solve_Pell` | Fundamental $(X,Y)$ with $X^{2}-NY^{2}=1$, $Y>0$ |
| `Solve_Pell_With_Chain` | Same + educational $(a,b,k)$ / $m$ chain |
| `Verify_Pell` / `Verify_Triple` | Check returned identities |

`Solve_Pell` raises `Invalid_Argument` when $N\le 0$, $N>\texttt{Max\_N}$,
or $N$ is square.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
