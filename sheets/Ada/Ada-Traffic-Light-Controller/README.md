# Ada Traffic Light Controller

Clean-room **MIT** educational sketch of a two-axis (NS/EW) traffic-light
controller in **Ada 2022**, with a small verification-and-validation (V&V)
test suite. No Alire crate, no GPL dependencies, no SPARK Level-2 proof
obligation (assertions via `-gnata` only).

The project is inspired by the *idea* of teaching trust around AI-generated
artifacts using a traffic-light / intersection narrative — **not** a fork or
port of AdaCore’s Foundry demo sources, requirements tree, or AI configs.

## Related reading (citation only)

- Forum thread: [Building Trust in AI-Generated Artifacts / gnat-foundry-intersection](https://forum.ada-lang.io/t/building-trust-in-ai-generated-artifacts-gnat-foundry-intersection/4742)
- AdaCore GNAT Foundry intersection / traffic-light materials (Apache-licensed demo) — read for motivation; this repo’s Ada was written separately under MIT.

## Packages

| Package | Role |
|---------|------|
| `Traffic_Phases` | `Red` / `Yellow` / `Green`; optional `Walk` / `Dont_Walk`; conflict helpers |
| `Intersection_FSM` | NS/EW axes; transitions; never both Green; all-red clearance; Fault → All_Red |
| `Phase_Timers` | Min-green, yellow, all-red tick holds; `Advance` gated on `Tick` |
| `tests.adb` | Conflict rejected, happy cycle, fault all-red, timer gates |

## Safety properties (runtime / tests)

1. **Mutual exclusion** — `Conflicts` rejects simultaneous Green (and Green∩Yellow cross-axis).
2. **All-red clearance** — the cross axis may receive Green only from All_Red.
3. **Fault** — `Raise_Fault` forces both axes Red and blocks further grants until `Clear_Fault`.
4. **Timer gates** — `Phase_Timers.Advance` fails until the configured ticks elapse.

## Build & test

```bash
make test
```

Uses `gnatmake -gnatwa -gnat2022 -gnata` (warnings-as-visible, Ada 2022, assertions).

Expected footer shape:

```text
===  NN passed, 0 failed ===
```

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational
project. The Ada sources and tests were checked locally with GNAT
(`make test`). This repository is an original clean-room MIT work and does
**not** copy AdaCore Foundry intersection code, requirements, or AI configs.

## License

MIT — see [LICENSE](LICENSE).
