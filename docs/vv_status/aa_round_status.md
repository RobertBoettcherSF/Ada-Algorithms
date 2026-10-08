# AA round status — fixed_origin room decision (2026-10-08)

## Mechanical KEEP test
KEEP fixed origin ONLY if the algorithm does arithmetic on the index values themselves
(heap 2*I / I/2, Fenwick I and -I, FFT bit-reversal, 1-based DP, interpolation probe,
package-merge 2*P, polynomial degree index Poly(I)*I). Indexes that only walk or line
arrays up → First-relative rewrite. No judgment beyond that test.

## Ledger (`tools/vv/fixed_origin_decisions.tsv`)
- **7 KEEP** (subtypes preferred; one-line arithmetic reason in CSV `note`)
- **83 REWRITE**

### KEEP (7)
| Folder | Reason |
|--------|--------|
| sorting/SPARK4/Ada-SPARK-Heapsort | Left:=2*I, A(2*I), A(I/2), 2*R hole/child |
| sorting/SPARK4/Ada-SPARK-Introsort | Left:=2*I, A(2*I), A(I/2), 2*R |
| sorting/SPARK4/Ada-SPARK-Smoothsort | Leonardo/smoothsort child roots |
| searching/SPARK4/Ada-SPARK-Interpolation-Search | probe uses Lo/Hi as numeric positions |
| strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt | 1-based KMP prefix Pi(i)/Len:=Pi(Len) |
| misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm | package-merge pairs 2*P-1 / 2*P |
| compression/Ada/Peterson-Gorenstein-Zierler-Algorithm | coeff index = degree (Derivative Poly(I)*I); subtype Degree_Poly First=0; syndromes First-rel |

### Rewritten First-relative (13) — green make test + CSV `rewritten_first_relative`
BCJR, N-Body, Spline (Thomas), Levinson, Memetic (TSP), Thomas, Floyds-Cycle, Brents,
Barnes-Hut, Gale-Shapley, Min-Conflicts, Hungarian, Top-Trading-Cycle.

### Still stamped `rewrite_first_relative` / fail (~70)
Bulk SPARK4 classroom + remaining Ada (FLAME, ACO, Branch-and-Bound, Combinatorial-Opt,
Fast-Multipole, …). Pins still First=1; code rewrite not done yet.

## Other tracks (same tip)
- `kill_kind=uninit` in mutate/sweep_mutate + VV.md (committed with room decision)
- p23 flaky still running (~1680/1758); no f14_done yet
- Tip: see `git log -1`
