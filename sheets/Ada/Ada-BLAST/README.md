# BLAST — Basic Local Alignment Search Tool (Ada 2023)

Educational, self-contained Ada 2023 package for
[Wikipedia: Basic Local Alignment Search Tool](https://en.wikipedia.org/wiki/Basic_Local_Alignment_Search_Tool):
**BLAST**, the heuristic local similarity search introduced by
**Stephen F. Altschul**, Warren Gish, Webb Miller, Eugene W. Myers, and
David J. Lipman (*J. Mol. Biol.* 215, 1990). BLAST finds high-scoring local
alignments between a **query** sequence and a **database** (here: a single
in-memory **subject**) without the full quadratic cost of classical
Smith–Waterman on every pair.

This repository is a **pedagogical subset** — exact DNA word seeds of length
$W$, ungapped **X-drop** extension to **HSPs**, optional short
Smith–Waterman for gapped comparison — **not** NCBI BLAST / BLAST+
(no neighborhood words, two-hit rule, Karlin–Altschul $E$-values, or
threaded databases).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Alphabet** | $\{\mathrm{A},\mathrm{C},\mathrm{G},\mathrm{T}\}$ | Case-insensitive; non-ACGT windows skipped |
| **Scoring** | Match $+2$, mismatch $-1$ | Configurable `Score_Params` |
| **Seeds** | Exact $W$-mers | `Build_Index` / `Find_Word_Hits` |
| **Extension** | Ungapped X-drop | `Extend_HSP` → HSP endpoints + score |
| **Reporting** | Dedup + top scores | `Search` → `HSP_List` |
| **Gapped (opt.)** | Smith–Waterman | `Smith_Waterman_Local` on short pairs |
| **Capacity** | `Max_Seq_Len = 400` | Educational in-memory bound |

## History and heuristic idea

Full local alignment (Smith–Waterman) scores every cell of an
$|Q|\times|S|$ dynamic-programming matrix. BLAST replaces exhaustive DP with
a **seed-and-extend** heuristic:

1. Index subject words of length $W$.
2. Find exact (or, in production BLAST, high-scoring neighborhood) matches
   to query words — the **seeds**.
3. Extend each seed without gaps until the score falls more than $X$ below
   the best score seen along the path (**X-drop**).
4. Keep **high-scoring segment pairs** (HSPs) above a threshold; optional
   gapped refinement follows in later BLAST generations.

The 1990 paper established BLAST as the practical workhorse of sequence
database search; later variants (Gapped BLAST, PSI-BLAST, BLAST+) add
two-hit seeding, gapped extension, and position-specific scoring.

## Scoring

For aligned bases $q_i,s_j$ under parameters $(m,\mu)$ (match / mismatch):

$$
\sigma(q_i,s_j)=
\begin{cases}
m & \text{if }q_i=s_j,\\
\mu & \text{otherwise.}
\end{cases}
$$

Default pedagogical DNA scores: $m=2$, $\mu=-1$. Optional linear gap
penalty $g$ (default $-2$) is used only by `Smith_Waterman_Local`.

Ungapped alignment score of equal-length strings is
$\sum_k \sigma(q_k,s_k)$.

## Seeds and word hits

With word length $W$, every contiguous subject substring
$s_j s_{j+1}\cdots s_{j+W-1}$ over ACGT is indexed. Query windows of length
$W$ that match exactly become **word hits** $(q_{\mathrm{start}},
s_{\mathrm{start}})$. DNA literature often uses $W\approx 11$; this package
supports $W\in[1,12]$ with small in-memory subjects (tests typically use
$W=2..6$).

## X-drop extension and HSPs

From a seed of length $W$ with seed score $S_0$, extend right (then left).
Let $R_t$ be the running score after $t$ steps. Stop when

$$
R_t < \max_{u\le t} R_u - X.
$$

The retained HSP is the interval attaining the best combined left/right
score. An HSP record stores
$(q_{\mathrm{start}},q_{\mathrm{end}},s_{\mathrm{start}},s_{\mathrm{end}},
\mathrm{score})$. Overlapping HSPs are deduplicated (higher score wins);
`Search` returns the top scores in descending order.

## Smith–Waterman (optional gapped local)

For short pairs, classical local alignment with linear gaps:

$$
H_{i,j}=\max\bigl(0,\;
H_{i-1,j-1}+\sigma(q_i,s_j),\;
H_{i-1,j}+g,\;
H_{i,j-1}+g\bigr).
$$

The optimum is $\max_{i,j} H_{i,j}$ with traceback to endpoints. This is
$O(|Q||S|)$ and is exposed for comparison / refinement — not as a
replacement for the BLAST heuristic on long subjects.

## Heuristic vs full SW

| | BLAST-like (this package) | Smith–Waterman |
| --- | --- | --- |
| Time (typical) | Near-linear in subject with indexing | $\Theta(\|Q\|\|S\|)$ |
| Gaps in core path | Ungapped X-drop | Affine/linear gaps |
| Completeness | Heuristic (may miss weak locals) | Exact local optimum |
| Role here | Primary `Search` | `Smith_Waterman_Local` check |

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Score_Params`, `Word_Index`, `Word_Hit`, `Hit_List`, `HSP_Record`, `HSP_List`, `SW_Result` | Core records |
| Scoring | `Pair_Score`, `Ungapped_Score`, `Default_Scores` | Match/mismatch (+ gap for SW) |
| Index | `Build_Index`, `Index_W`, `Index_Subject_Length`, `Index_Entry_Count` | Subject $W$-mers |
| Hits | `Find_Word_Hits` | Exact seeds |
| Extend | `Extend_HSP`, `HSP_Length`, `HSPs_Overlap`, `Best_HSP` | X-drop HSPs |
| Search | `Search` | Full seed→extend→dedup pipeline |
| SW | `Smith_Waterman_Local` | Short gapped local |
| Helpers | `Is_ACGT`, `Normalize_Base`, `Normalize_Sequence`, `All_ACGT`, `Near` | Alphabet / numerics |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`). Capacity: `Max_Seq_Len = 400`, `Max_W = 12`,
`Max_HSPs = 64`, `Max_Hits = 512`.

## Build and test

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pblast.gpr
make test                 # runs bin/tests; expect Fail_Count=0 and ≥100 PASS
```

Requirements: GNAT (GCC Ada) with Ada 2022/2023 support.

## Layout

Exactly seven root entries (no `main.adb`):

1. `blast.ads`
2. `blast.adb`
3. `blast.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- [Wikipedia: Basic Local Alignment Search Tool](https://en.wikipedia.org/wiki/Basic_Local_Alignment_Search_Tool)
- Altschul, S.F., Gish, W., Miller, W., Myers, E.W. & Lipman, D.J. (1990),
  *Basic local alignment search tool*, J. Mol. Biol. 215:403–410
- Altschul et al. (1997), Gapped BLAST and PSI-BLAST, *Nucleic Acids Res.*
- Smith, T.F. & Waterman, M.S. (1981), Identification of common molecular
  subsequences, *J. Mol. Biol.*

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
