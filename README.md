# Ada-Algorithms

Resource-efficient **monorepo of Ada algorithm packages** (educational sheets).

**Not included here:** larger projects such as Logistics, Rule-30, Blauer Sand /
`lern_engine` — those stay in their own repositories.

## Explore / test

```bash
make            # build harness + all test binaries
make list       # list algorithms (name + category)
make test                # run every seeded algo's tests
make test CAT=sorting    # one category only
make clean
```

Harness CLI (same as the Make targets):

```bash
bin/harness --list
bin/harness --category sorting
bin/harness --all
```

Build flags match the sheet style: `-gnatwa -gnat2022` (GNAT / Ada 2022).

## Seeded so far

| Algorithm       | Category  | Source sheet              |
|-----------------|-----------|---------------------------|
| quicksort       | sorting   | Ada-Quicksort             |
| heapsort        | sorting   | Ada-Heapsort              |
| binary_search   | searching | Ada-Binary-Search         |

Further Ada-* algorithm sheets will be migrated in later batches. Per-algo
upstream repos are left intact.

## Archival sheet dump

Unmodified copies of upstream algorithm sheet repos live under [`sheets/`](sheets/)
(`Ada/`, `SPARK1`…`SPARK4`). See [`sheets/README.md`](sheets/README.md).

