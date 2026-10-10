# Pinned toolchain

Every proof and build result in this repository names the tools that produced it. This file pins those tools so a later machine can rebuild the same setup with one command. Proof step counts (`--steps`) do not depend on machine speed, but they do depend on the gnatprove and solver versions, so a step-budget result can only be reproduced with the same releases.

## One-command restore

Requires [Alire](https://alire.ada.dev) `alr` 2.x on PATH (the box uses `alr 2.1.1`, `~/.local/alr/bin/alr`). From the repository root:

```sh
eval "$(cd tools/toolchain && alr -n printenv)"   # downloads the locked crates on first use, then puts them on PATH
gnatprove --version; gnatls --version             # FSF 16.1.0 / GNATLS 12.2.0
```

`alr` reads `tools/toolchain/alire.toml` and the committed lockfile `tools/toolchain/alire/alire.lock`; the lockfile records each crate's version, download URL and sha256. On a brand-new `alr` install, run `alr -n index --reset-community` once if it has no index yet. Also on a brand-new install, the first crate command may start Alire's toolchain assistant; under `-n` it picks a default compiler and saves it in the global settings. This crate is not affected, because the locked `gnat_native` wins, but to leave the global settings alone, run `alr settings --global --set toolchain.assistant false` once first. Do not use apt or other distribution packages for these tools.

The second compiler (the "GNAT 14" column) has its own manifest, because one Alire workspace holds one GNAT:

```sh
eval "$(cd tools/toolchain/gnat14 && alr -n printenv)"   # GNATLS 14.2.0 (Alire gnat_native 14.2.1)
```

## What is pinned

| Role | Alire crate (exact) | Reports | Archive (from the lockfile) |
|---|---|---|---|
| Prover | `gnatprove = "=16.1.0"` | `FSF 16.1.0`, `Why3 for gnatprove version 1.8.2+git` | GNAT-FSF-builds `gnatprove-x86_64-linux-16.1.0-1.tar.gz`, sha256 `82528bef...` |
| Solver (bundled) | in gnatprove 16.1.0 | `cvc5 version 1.3.2 [git 86cecd8]` | `libexec/spark/bin/cvc5` |
| Solver (bundled) | in gnatprove 16.1.0 | `Z3 version 4.15.4 - 64 bit` | `libexec/spark/bin/z3` |
| Solver (bundled) | in gnatprove 16.1.0 | `Alt-Ergo version 2.6.1` | `libexec/spark/bin/alt-ergo` |
| Solver | - | colibri is not in this gnatprove build | - |
| GNAT 12 compiler | `gnat_native = "=12.2.1"` | `GNATLS 12.2.0` | `gnat-x86_64-linux-12.2.0-1.tar.gz`, sha256 `11f3b811...` |
| Builder | `gprbuild = "=26.0.1"` | `GPRBUILD 26.0.0 (2026-04-15)` | `gprbuild-x86_64-linux-26.0.0-1.tar.gz`, sha256 `e3f27f25...` |
| GNAT 14 stand-in | `gnat_native = "=14.2.1"` (`tools/toolchain/gnat14`) | `GNATLS 14.2.0` | `gnat-x86_64-linux-14.2.0-1.tar.gz`, sha256 `06bb3def...` |

The solver versions were read from the binaries inside the restored crate (`alr exec -- .../libexec/spark/bin/<solver> --version`), and they match the `solver_*` lines of `tools/vv/prove_settings.txt` (the re-proof settings file; at the time of writing it was still uncommitted in the main worker's checkout). The Alire crate version and the version a tool reports are different strings: crate `gnat_native 12.2.1` reports `GNATLS 12.2.0`, and crate `gprbuild 26.0.1` reports `GPRBUILD 26.0.0`. Results record the reported string (docs/VV.md, compiler-version guard).

## GNAT 14.2.0 is not an Alire crate

The "GNAT 14" builds so far used the **system** compiler: Debian package `gnat-14` version `14.2.0-19` (`/usr/bin/gnat`, `GNATLS 14.2.0`). Alire cannot pin a distribution package; it only detects it as `gnat_external`, which is whatever the host has installed. The nearest Alire equivalent is `gnat_native 14.2.1`, which is GNAT-FSF-builds' packaging of the same upstream GCC 14.2.0 release and also reports `GNATLS 14.2.0`. It is a different build from Debian's (different patches and build options), so it is pinned separately in `tools/toolchain/gnat14/`, and a result from one is not claimed for the other. Both are recorded here:

- used so far: Debian `gnat-14 14.2.0-19` (GNATLS 14.2.0), not restorable with `alr`;
- restorable stand-in: Alire `gnat_native=14.2.1` (GNATLS 14.2.0), lockfile `tools/toolchain/gnat14/alire/alire.lock`.

## Verification of the restore (2026-10-09)

- Scratch Alire settings `~/.local/alr/restore-check/settings` (fresh community index, empty cache, toolchain assistant off, external GNAT off). `alr -n update` in `tools/toolchain` downloaded gnat_native 12.2.1, gnatprove 16.1.0 and gprbuild 26.0.1. The sha256 prefixes match the crates the box has used since 2026-10-07 (`~/.local/alr/gnat_native_12.2.1_11f3b811`, `gnatprove_16.1.0_82528bef`, `gprbuild_26.0.1_e3f27f25`).
- `alr exec` then reported `GNATLS 12.2.0`, `FSF 16.1.0`, `Why3 ... 1.8.2+git`, `GPRBUILD 26.0.0`, cvc5 1.3.2 (86cecd8), Z3 4.15.4 and Alt-Ergo 2.6.1.
- A second directory holding only `alire.toml` and the lockfile restored the same versions with `alr exec`, and the lockfile was left unchanged.
- `tools/toolchain/gnat14`: gnat_native 14.2.1 restored; `gnatls --version` reports `GNATLS 14.2.0`.

## Environment variables used by the scripts

The scripts under `tools/` find the repository from their own location and never hard-code a box path (`make check-paths` fails on any absolute box path in a tracked file).

| Variable | Default | Used by |
|---|---|---|
| `AA_ALR_DIR` | `~/.local/alr` (Alire's crate cache on the box: `gnat_native_12.2.1_*`, `gnatprove_16.1.0_*`, `gprbuild_*`) | `tools/audit/build_folder.sh`, `prove_folder.sh`, `tools/vv/sweep_check.sh`, `sweep_gnat_recheck.sh`, `reproof.sh`, `always_terminates_check.sh`, `proof_warnings.py`, `score138_prove.py`, `flaky.py`, `silent_fail.py` |
| `GNAT12_BIN`, `GPRBUILD_BIN`, `GNATPROVE_BIN` | the matching `bin` dir under `AA_ALR_DIR` | `tools/audit/*.sh` (override one tool) |
| `TMPDIR` | `/tmp` (Python `tempfile.gettempdir()`, shell `mktemp`) | every `--work` / scratch default (`sweep_mutate.py`, `reproof.py`, `run_vv.sh` `VV_OUT`, `make vv-validate` `RESULTS`/`PROVE_LOGS`; bare `make proof-index` no longer reads them, it synthesises its inputs from PROOFS.csv (H188), ...) |
| `AA_S138_PRIVATE` | `<parent of the checkout>/s138_private` (outside git, so held-out results never land in a commit) | `tools/vv/score138.py --out`, `score138_record.py` |

With `eval "$(cd tools/toolchain && alr -n printenv)"` the tools are already on PATH; `AA_ALR_DIR` only matters for the scripts that pin a crate by folder name.

## Changing the toolchain

A new gnatprove or solver version is a new proof setup: re-run the whole cold re-proof, update this file and `prove_settings.txt`, and leave every result proved under the old setup labelled with that setup. Never mix the two in one claim.
