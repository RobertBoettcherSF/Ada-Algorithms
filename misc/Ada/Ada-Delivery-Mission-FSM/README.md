# Ada-Delivery-Mission-FSM

Autonomous doorstep delivery missions move through a short lifecycle — idle, pickup, transit, last yards, doorstep unlock, and return — with fault and remote-assist side doors. This tiny Ada FSM accepts only legal transitions and rejects illegal ones (e.g. Pickup→Unlock), as a clean-room educational sketch of Rivr-like mission sequencing, not Rivr proprietary code.

## Build & test

```bash
make test
```

Uses GNAT with `-gnatwa -gnat2022 -gnata`. No Alire.

## Optional SPARK

```bash
make prove   # SPARK L2 — proved clean on this package
```

## License

MIT. See `LLM_DISCLOSURE.md`.
