# Ada-GNAT-Studio-Notes

Docs-heavy **GNAT Studio / editor on-ramp** for Ada + SPARK sheets: Linux open tips, Alire-edit folklore (informational only — **no** `alire.toml`), and a tiny SPARK package so the repo is not docs-only vapor.

Community thread:
[forum.ada-lang.io — IDE: your alternative to GNAT Studio](https://forum.ada-lang.io/t/ide-your-alternative-to-gnatstudio/85)

## Index

| Doc | Topic |
|-----|--------|
| [docs/gnatstudio-linux.md](docs/gnatstudio-linux.md) | Opening Makefile+GPR sheets in GNAT Studio on Linux, SPARK via `make prove` |
| [docs/alire-edit-pitfalls.md](docs/alire-edit-pitfalls.md) | `alr build` before `alr edit`, project-tree pitfalls — **informational only** |

Optional smoke script:

```bash
make check          # or: bash scripts/open-checks.sh
```

## Real SPARK sample (not vapor)

`Studio_Probe.Abs_Diff` — absolute difference of two bounded integers, SPARK_Mode On, with V&V tests and GNATprove Level 2 (`cvc5`, warnings/checks as errors).

```bash
source /home/box/deps/spark/env.sh   # adjust to your install
make test
make prove
```

No Alire manifest (Makefile + GPR only).

## License

MIT — see [LICENSE](LICENSE).

## LLM usage disclosure

AI assistance (LLM) was used to draft this repository’s documentation, scripts, sample SPARK package, tests, and README. Human review and local `make test` / `make prove` validation were required before publish.
