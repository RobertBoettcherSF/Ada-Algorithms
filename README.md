# Ada-Algorithms

Resource-efficient **monorepo of Ada algorithm packages** (educational sheets).

**Not included here:** larger projects such as Logistics, Rule-30, Blauer Sand /
`lern_engine` — those stay in their own repositories.

## Layout

Flat sheet dumps by **topic**, then prove level:

```
sorting/Ada/…          # plain Ada sheet files (as-is)
sorting/SPARK2/…
searching/Ada/…
…/SPARK1|SPARK2|SPARK3|SPARK4/…
misc/…
```

On basename clashes with different content, files are renamed
`<GitHubRepo>__<basename>` (e.g. `Ada-Quicksort__tests.adb`). Identical
files (same sha256) are stored once. Package sources are not rewritten.

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
