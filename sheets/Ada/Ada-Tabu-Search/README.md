# Tabu Search — Ada 2023

Educational, self-contained Ada 2023 package implementing **tabu search**
(TS) — a **metaheuristic** local search that explores a discrete
neighborhood by always accepting the **best admissible** neighbor (which
may worsen the objective), while a short-term **tabu list** forbids
reversing recent moves. An **aspiration** criterion may override tabu
when a candidate improves the global best.

Based on [Wikipedia: Tabu search](https://en.wikipedia.org/wiki/Tabu_search)
(Fred W. Glover, 1986; formalized 1989).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Simulated-Annealing](../ada-simulated-annealing/)**
(Metropolis cooling on continuous / TSP-lite landscapes) and
**[Ada-Random-Search](../ada-random-search/)** (budgeted random hyperparameter
sampling). Tabu search is deterministic given the neighborhood order; SA
accepts uphill moves probabilistically; random search does not walk a
neighborhood.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Best admissible neighbor each step | May worsen to escape local minima |
| **Memory** | Short-term circular attribute list | Tenure $t$; forbid recent reverse moves |
| **Aspiration** | Override tabu if $f(x')<f^\star$ | Common “beats global best” rule |
| **Demos** | OneMax / Hamming, TSP 2-opt, partition | $n\le 32$ bits; $n\le 12$ cities |
| **Track** | Best-so-far $x^\star$ | Updated on strict improvement |

## Brief history

Glover introduced tabu search in 1986 and formalized the framework in
1989. The method relaxes strict descent: worsening moves are allowed when
no improving admissible move exists, and **tabu** prohibitions discourage
cycling through recently visited attributes. The word *tabu* comes from
Tongan, for things that must not be touched. Applications span scheduling,
telecommunications, VLSI, logistics, and many other combinatorial domains.
TS is often compared with simulated annealing, genetic algorithms, and
related metaheuristics; hybrids with scatter search are common.

## Short-term tabu memory

At iteration clock $\tau$, an attribute $a$ recorded with tenure $t$
remains tabu while

$$
\tau < \mathrm{expiry}(a),\qquad \mathrm{expiry}(a)=\tau_{\mathrm{push}}+t.
$$

A move with attribute $a$ is **admissible** if it is not tabu, or if
aspiration applies:

$$
a\notin\mathrm{Tabu}\;\lor\;\bigl(f(x')<f^\star\bigr).
$$

The list is a circular buffer of capacity $M$ (`Max_Tabu`); when full,
new pushes overwrite the oldest slot.

## Search step

From current solution $x$, evaluate the neighborhood $N(x)$. Among
admissible neighbors, select

$$
x\leftarrow\arg\min_{x'\in N^\star(x)} f(x'),
$$

where $N^\star(x)$ is the admissible subset (tabu filtered, aspiration
included). Update $f^\star$ when $f(x)<f^\star$, push the chosen move’s
attribute onto the tabu list, and repeat until the iteration budget (or
a zero-cost optimum for demos that admit one).

## Concrete neighborhoods

| Demo | State | Move / attribute | Cost |
| --- | --- | --- | --- |
| `Minimize_OneMax` / `Minimize_Hamming` | bit-string | flip bit $i$ / attr $=i$ | zeros or Hamming to target |
| `Minimize_TSP` | tour $n\le 12$ | 2-opt $(i,j)$ / packed attr | closed tour length |
| `Minimize_Partition` | $\pm$ assignment | flip item $i$ / attr $=i$ | $\lvert\sum A-\sum B\rvert$ |

OneMax is encoded as **minimizing the number of zeros** (equivalently
Hamming distance to the all-ones string).

## Versus simulated annealing

| | Tabu search (TS) | Simulated annealing (SA) |
| --- | --- | --- |
| Neighbor choice | Best admissible (deterministic) | Random proposal |
| Escape mechanism | Tabu + optional worsening | Metropolis $P=\min(1,e^{-\Delta E/T})$ |
| Memory | Explicit short-term list | Temperature schedule only |
| Aspiration | Override tabu for new global best | N/A |

See the sibling **Ada-Simulated-Annealing** repository for Metropolis
cooling on $E(x)$.

## API (`Tabu_Search`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Config`, `Result`, `Tabu_List`, `Tabu_Entry` | Tenure, capacity, iters |
| Tabu | `Clear`, `Push`, `Contains`, `Is_Admissible`, `Active_Count`, `Set_Clock` | Circular attribute memory |
| Helpers | `Near` | Absolute tolerance compare |
| Bits | `Minimize_OneMax`, `Minimize_Hamming`, `Flip_Bit`, `Hamming_Distance` | OneMax / Hamming |
| TSP | `Tour_Length`, `Apply_2Opt`, `Encode_2Opt_Attr`, `Minimize_TSP` | 2-opt $n\le 12$ |
| Partition | `Partition_Cost`, `Minimize_Partition` | Number partitioning |

Named exception: `Invalid_Argument`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Tabu search](https://en.wikipedia.org/wiki/Tabu_search)
- F. Glover, *Future paths for integer programming and links to
  artificial intelligence*, Comput. Oper. Res. **13**, 533–549 (1986)
- F. Glover, *Tabu Search — Part I*, ORSA J. Comput. **1**, 190–206 (1989)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)
- Sibling: [Ada-Random-Search](../ada-random-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
