# Alire edit pitfalls (informational only)

**This repository does not ship an Alire manifest** (`alire.toml`). Makefile + GPR is the supported workflow here, matching the user / org policy for these sheets.

The notes below summarize common forum / community friction when people *do* use Alire elsewhere, so GNAT Studio / editor users are not blindsided.

## `alr build` before `alr edit`

A recurring gotcha: running `alr edit` (or opening the generated project) **before** a successful `alr build` can leave you with:

- Incomplete or missing generated project files
- An editor session pointed at a tree that does not yet match dependencies
- Confusing “where are my sources?” moments in GNAT Studio / ALS

**Practical habit (when you use Alire on other projects):**

```bash
alr build
alr edit
```

Build first so the pin / dependency / generated GPR story is materialised, then open the editor.

## Project tree issues

From community IDE discussions (including the [ada-lang.io GNAT Studio alternatives thread](https://forum.ada-lang.io/t/ide-your-alternative-to-gnatstudio/85)):

- Editors may attach to the wrong root if you open a subdirectory instead of the crate / GPR root.
- Multiple `.gpr` files (build vs proof vs generated) confuse “which project is active?” — set the language server / Studio project explicitly.
- Mixing Alire-generated trees with hand-written Makefiles without a clear source of truth causes drift.

## Policy reminder for this sheet

| Do | Don’t |
|----|-------|
| Use `make test` / `make prove` | Add `alire.toml` here |
| Open `sample.gpr` in Studio / ALS | Assume Alire is required for the on-ramp |
| Read this doc as folklore insurance | Treat Alire commands as part of this repo’s CI |

If you maintain a separate Alire-based project, keep that workflow there; do not backport manifests into these tooling on-ramps.
