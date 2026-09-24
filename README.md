# Ada-Algorithms

Resource-efficient **monorepo of Ada algorithm packages** (educational sheets).

**Not included here:** larger projects such as Logistics, Rule-30, Blauer Sand /
`lern_engine` — those stay in their own repositories.

## Layout

Algorithm packages are organized by **topic**, then proof level, with one
folder per source repository:

```
sorting/Ada/Ada-Quicksort/…
sorting/SPARK2/Ada-Quicksort/…
searching/Ada/Ada-Binary-Search/…
…/SPARK1|SPARK2|SPARK3|SPARK4/<GitHubRepo>/…
```

Files formerly renamed `<GitHubRepo>__<basename>` are stored as
`<GitHubRepo>/<basename>` (leading-dot names are preserved). Files without a
clash prefix remain at the topic/level root. Identical files (same sha256) are
stored once. Package sources are not rewritten.

See [`TOPICS.md`](TOPICS.md) for per-topic / per-level file counts.

## Explore / test (integrated harness)

A small seeded harness (independent of the flat topic dumps) lives under
`src/` and `tests/`:

```bash
make            # build harness + seed test binaries
make list       # list seeded algorithms
make test                # run all seed tests
make test CAT=sorting    # one category only
make clean
```

```bash
bin/harness --list
bin/harness --category sorting
bin/harness --all
```

Build flags: `-gnatwa -gnat2022`.

## Seeded harness algos

| Algorithm     | Category  |
|---------------|-----------|
| quicksort     | sorting   |
| heapsort      | sorting   |
| binary_search | searching |
