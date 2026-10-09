# Ada-Algorithms

Monorepo of small Ada and SPARK algorithm folders (educational sheets). MIT license
(`LICENSE`). Larger projects such as Logistics, Rule-30 and Blauer Sand /
`lern_engine` live in their own repositories.

<!-- proof-index:begin -->
| Headline (written by `make proof-index`) | Folders |
|---|---:|
| Algorithm folders (duplicates counted once) | 1838 |
| Silver-proven, non-trivial (not stubs, more than 3 checks) | 503 |
| Training-ready under rule v1 (held-out n >= 20, >= 90%, proof pass; docs/VV.md "Rule v1"), count as of 2026-10-09: 64 folders. Blind held-out mutation >= 90% with n >= 20, independent reference, index-independent, 0 warnings on GNAT 14 and 12 without suppression, no withdrawn or partial functional claim, no unexplained proof escape; reasons in PROOFS.csv `tr_drop`. Unseen top-up scores are shown next to each held-out score in PROOFS.md and are not counted | 64 |
| Training-ready under the previous rule | 273 |
| Open findings (`tools/vv/findings.csv`) | 68 |
| Implementation candidates (stubs, column `implement_next`; docs/IMPLEMENT.md) | 145 |
<!-- proof-index:end -->

These numbers are written by `make proof-index` from the build and proof records
(never by hand); per-folder data is in [`PROOFS.md`](PROOFS.md) / `PROOFS.csv`.

## Layout

One self-contained folder per algorithm, grouped by topic and level:

```
<topic>/Ada/<Folder>/             plain Ada
<topic>/SPARK1..SPARK4/<Folder>/  SPARK variants
```

e.g. `sorting/Ada/Quicksort`, `sorting/SPARK2/Ada-SPARK-Sort-List-Lite`. Some
algorithms exist in both an Ada and a SPARK folder (column `pair` in PROOFS.csv).
A folder holds its sources, a `Makefile`, a `README.md` and its tests (`tests.adb`
or `tests/`). [`TOPICS.md`](TOPICS.md) has file counts per topic and level.

## Build, test, prove a folder

```bash
cd sorting/SPARK2/Ada-SPARK-Sort-List-Lite
make                 # default target: build (in many folders it also runs the tests)
make test            # build and run the folder's tests
gnatprove -P <gpr> --mode=silver --level=2   # the folder's .gpr, or proof.gpr where present
```

Many SPARK folders also have `make prove`. GNAT 12 and GNAT 14 are both supported;
the compiler first on `PATH` is used. The index builds every folder with
`gnatmake -gnatwa -gnat2022` on both and records failures and warning counts
(columns B12/B14, W12/W14 in PROOFS.md). `gnatprove` and `gprbuild` come from Alire.

The root `Makefile` builds a small seeded harness (`src/`, `tests/`): `make test`
runs it (`make test CAT=sorting` for one category, `make list` to list it).

## What a proof does and does not say

Silver means proven free of run-time errors (no overflow, index or range check can
fail). It does **not** mean the answers are right: a function that always returns 0
can be Silver. The folders whose answers are checked are those with
`training_ready` = yes in [`PROOFS.md`](PROOFS.md). The rule: builds and tests pass
on GNAT 12 and 14, the folder's own `make test` passes on both, Silver-proven
non-trivially, not a stub, no open finding, and a known answer (a known-answer
vector, our own tests, or agreement with its Ada/SPARK twin) whose tests the
do-nothing check does not flag as weak.

`make vv` reruns the checks behind that column (builds and `make test` on GNAT 14
and 12, proofs with a step budget, differential tests between twins, sampled
mutation testing, the do-nothing check) and then refreshes the index and the
numbers above. Details and current results: [`docs/VV.md`](docs/VV.md).

## Tests and findings

All tests are our own: our own brute-force references or properties, or
public-domain / BSD standard vectors. Where every expected value comes from is in
each folder's `tests/SOURCES.txt`. Nothing is taken from GPL or GFDL sources.

Wrong answers and undocumented behaviour found by these checks are recorded in
`tools/vv/findings.csv` (open / fixed, with the commit that added the failing
test and the commit that fixed it).
