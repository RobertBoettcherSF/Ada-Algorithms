# Ada-Locomotion-Mode-Interlock

Hybrid wheeled/legged delivery platforms must not mix locomotion modes unsafely: legs while wheels are armed need an explicit hybrid transition, stairs need legs or hybrid, and each mode has its own speed cap. This tiny Ada interlock is a clean-room educational sketch of Rivr-like mode gating for last-meter doorstep robots — not Rivr proprietary code.

## Build & test

```bash
make test
```

Uses GNAT with `-gnatwa -gnat2022 -gnata`. No Alire.

## Optional SPARK

```bash
make prove   # SPARK L2 — proved clean on this package
```

## SI units

See [SI_Units.md](SI_Units.md). Mode caps remain `Speed_Cm_S` (cm/s); new physical APIs should use unit suffixes (`Speed_m_s`, …). Docs-only for this slice.

## License

MIT. See `LLM_DISCLOSURE.md`.
