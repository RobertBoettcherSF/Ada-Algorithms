# Gene Expression Programming — Ada 2023

Educational, self-contained Ada 2023 package implementing **gene expression
programming** (GEP; Ferreira 2001): fixed-length linear genes with a
**head** / **tail** structure, Karva (level-order) decode into expression
trees, and a tiny symbolic-regression driver.

Based on [Wikipedia: Gene expression programming](https://en.wikipedia.org/wiki/Gene_expression_programming)
(Ferreira; genotype–phenotype evolutionary algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  classical bit-string GA (selection / crossover / mutation)
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  EA + local search

Educational limits: head $h\le 6$, population $\le 40$, binary ops only
($n_{\max}=2$).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Gene** | Fixed string head+tail | Karva / ORF decode |
| **Length rule** | $t=h(n_{\max}-1)+1$ | Always-valid programs |
| **Functions** | `+`, `-`, `*`, `/` | Protected division |
| **Terminals** | `a`, `b`, optional `?` | Ephemeral constant |
| **Fitness** | $1/(1+\mathrm{MSE})$ | Symbolic regression toy |
| **Variation** | Mutation, 1-point xover | Transposition stub |
| **Selection** | $k$-tournament + elitism | Seeded LCG RNG |

## Brief history

Candida Ferreira introduced gene expression programming in 2001 as a
genotype–phenotype evolutionary algorithm: linear chromosomes of fixed
length (like genetic algorithms) express as parse trees of varied size
(like genetic programming). The head/tail gene layout guarantees that
every chromosome decodes to a syntactically valid expression. Multigenic
chromosomes, RNC domains, and cellular systems appear in later GEP
variants; this package focuses on the **basic educational unigenic**
algorithm for symbolic regression.

## Algorithm

### Gene geometry

A gene has head length $h$ and tail length

$$
t = h(n_{\max}-1)+1,
$$

so total length $g=h+t$. With binary operators, $n_{\max}=2$ and
$t=h+1$, $g=2h+1$. The head may hold functions and terminals; the tail
holds **terminals only**, providing a reservoir so every open reading
frame (ORF) is a valid expression tree.

### Karva decode

The k-expression is read in **level order** (breadth-first): the first
symbol is the root; each function of arity $r$ consumes the next $r$
unused symbols as children. Only the ORF prefix is expressed; unused
tail (and unused head) symbols are noncoding DNA.

Example: k-expression `*+-abab` encodes $(a+b)\times(a-b)$.

### Evaluation and fitness

Expression trees are evaluated on sample points $(a_i,b_i)$ with targets
$y_i$. Protected division returns the numerator when
$\lvert\mathrm{denominator}\rvert$ is tiny. Mean squared error

$$
\mathrm{MSE}=\frac{1}{N}\sum_{i=1}^{N}(\hat{y}_i-y_i)^2
$$

maps to fitness $f=1/(1+\mathrm{MSE})$ (higher is better). Toy targets:
$a+b$, $a\times b$, $a-b$.

### Evolution

Initialize a random population of genes. Each generation: copy elites,
$k$-tournament select parents, optional one-point homologous
recombination, per-locus mutation (head $\leftarrow F\cup T$, tail
$\leftarrow T$), rare transposition stub, re-evaluate. Terminate after
$G$ generations ($G=0$ yields an init-only result).

## API (package `Gene_Expression_Programming`)

| Entity | Role |
| --- | --- |
| `Gene` | Fixed-capacity chromosome (`Symbols`, `Head`, `Length`, `Ephemeral`) |
| `Config` / `Default_Config` / `Config_Is_Valid` | Pop, gens, head, rates, seed |
| `Tail_Length` / `Gene_Length_Of` | Ferreira length rule |
| `Make_Gene` / `Random_Gene` / `Gene_Is_Well_Formed` | Construction |
| `ORF_Length` / `Evaluate` / `Protected_Divide` | Decode + phenotype |
| `MSE` / `Fitness_Of` / `Fitness_From_MSE` | Symbolic-regression scores |
| `Mutate` / `Crossover_One_Point` / `Transpose_Stub` | Variation |
| `Make_Toy_Data` / `Evolve` / `Fit_Symbolic` | Drivers |
| `Near` | Numeric tolerance helper |
| `Seed_RNG` / `Next_Unit` / `Next_Natural` | Reproducible LCG |

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022
make test   # run bin/tests
make clean
```

Expect **zero** `-gnatwa` warnings and all tests passing.

## Caveats

- Educational caps only: $h\le 6$, pop $\le 40$; not a production GEP suite.
- Unigenic chromosomes; no multigenic linking, Dc/RNC domain, or GEP-NN.
- Function set is four binary arithmetic ops; no unary `Q` (sqrt) etc.
- Transposition is a short overwrite stub, not full IS/RIS transposition.
- Protected `/` is a simple epsilon guard, not IEEE specials handling.
- Symbolic regression toys are tiny and seeded; success is probabilistic
  but tests assert clear fitness improvement on $a+b$ / $a\times b$.

## References

- Ferreira, C. (2001/2006). *Gene Expression Programming: Mathematical
  Modeling by an Artificial Intelligence*.
- [Wikipedia: Gene expression programming](https://en.wikipedia.org/wiki/Gene_expression_programming)
