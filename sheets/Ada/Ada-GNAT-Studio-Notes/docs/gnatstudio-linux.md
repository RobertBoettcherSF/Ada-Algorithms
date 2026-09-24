# GNAT Studio on Linux — short notes

These notes are **informational**: a lightweight index for opening Ada / SPARK sheets in GNAT Studio without pretending Studio is the only path.

## Why this sheet exists

Many Ada learners start from forum threads that ask for an IDE story beyond (or beside) GNAT Studio. See:

[forum.ada-lang.io — IDE: your alternative to GNAT Studio](https://forum.ada-lang.io/t/ide-your-alternative-to-gnatstudio/85)

Companion on-ramps in this tooling set:

- **Ada-VSCode-SPARK-Workspace** — copy-paste `.vscode/` + ALS
- **Ada-Devcontainer** — one-click container / Codespaces compiler toolchain

## Opening a Makefile + GPR sheet in GNAT Studio

1. Install GNAT Studio from AdaCore (or your distro packaging, if available).
2. **File → Open Project…** and select this repo’s `sample.gpr` (or your sheet’s `.gpr`).
3. Prefer the project’s **Main** (`tests.adb` here) for Build / Run.
4. Keep object/exec dirs as in the `.gpr` (`obj/`, `bin/`) so Studio and `make` do not fight.

## SPARK / GNATprove from Studio

- GNATprove still needs a working SPARK install on `PATH`.
- This sheet’s canonical prove command is Makefile-driven:

  ```bash
  source /path/to/spark/env.sh
  make prove
  ```

- Level 2, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on` — same bar as the other RobertBoettcherSF SPARK sheets.

## Practical tips

- If Studio’s project view looks empty, confirm you opened the **`.gpr`**, not a lone `.adb`.
- After editing project structure, reload the project rather than chasing stale source lists.
- Use `make check` (`scripts/open-checks.sh`) for a quick “is this sheet intact?” smoke check before opening Studio.

## Out of scope

- Alire workflows (see `alire-edit-pitfalls.md` for **informational** pitfalls only — this repo ships **no** `alire.toml`).
- Full Studio keybinding customization.
