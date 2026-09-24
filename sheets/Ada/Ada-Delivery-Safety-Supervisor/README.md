# Ada-Delivery-Safety-Supervisor

Last-meter doorstep delivery robots need a hard safety envelope: capped speed, a simple geofence, teleop heartbeat, and an e-stop that always wins. This tiny Ada package is a clean-room educational bounded monitor that rejects overspeed commands, trips on geofence exit or teleop timeout, and restores motion only when e-stop is clear and the pose is safe again — generic Rivr-like motivation, not Rivr proprietary code.

## Build & test

```bash
make test
```

Uses GNAT with `-gnatwa -gnat2022 -gnata`. No Alire. V&V tests are the shipped assurance path.

## SPARK (optional / stalled)

`make prove` (SPARK L2) was attempted but did not finish within ~1 minute on this package (integer geofence / modular time interactions). **Shipped as V&V-only**; SPARK pragmas remain for future tightening but are not required to build or test.

## SI units

See [SI_Units.md](SI_Units.md). Runtime speed remains `Speed_Cm_S` (cm/s); new physical APIs should use unit suffixes (`Speed_m_s`, …). Docs-only for this slice.

## License

MIT. See `LLM_DISCLOSURE.md`.
