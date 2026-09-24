# sheets/ — as-is archival copies

Bulk dump of educational Ada algorithm sheet repositories from
`RobertBoettcherSF/*`, copied **unmodified** (Makefile, `.gpr`, README, tests,
sources). These are not wired into the monorepo harness.

## Layout

| Folder | Contents |
|--------|----------|
| `Ada/` | Plain (non-SPARK) `Ada-*` algorithm sheets |
| `SPARK1/` … `SPARK4/` | `Ada-SPARK-*` sheets grouped by gnatprove `--level=N` |

Example paths:

- `sheets/Ada/Ada-Quicksort/`
- `sheets/SPARK2/Ada-SPARK-Quick-Sort/`

SPARK bucket assignment: cheap grep of each tree’s Makefile / README / project
files for `--level=N` (or equivalent). If no level is found, default is
**SPARK2** (Pareto). Level 4 is never invented.

## Integrated harness (separate)

Runnable, category-oriented packages still live under repo-root `src/` and
`tests/` with `bin/harness`. That seed proof path is independent of `sheets/`.

## Exclusions (this batch)

Projects and non-sheets are not copied (e.g. Logistics, Rule-30, Blauer Sand /
`lern_engine`, ADAMS, Devcontainer, Raft, GUIs, Pages, AdaPGAS,
`Ada-Algorithms` itself). Empty GitHub stubs (size 0) are skipped.
`Ada-2022-*` language-feature sheets are deferred. Upstream sheet repos remain
intact on GitHub.
