# Ada-Beginner-Embedded-API

Clean-room educational Ada 2022 package offering an **Arduino-like beginner API** for digital pins: simple pin integers, one package, least surprise. Host-testable without real hardware.

This is an **educational simulator — not a full ADL/HAL**. Advanced HAL concerns and tasking are intentionally left out. Not affiliated with Arduino or Qualcomm.

## Motivation

Inspired by the Ada forum thread [*An embedded ecosystem for beginners*](https://forum.ada-lang.io/t/an-embedded-ecosystem-for-beginners/4296), especially Fabien.C’s advice: Arduino-like simplicity (simple pin integers, one package, least surprise), host-testable without real hardware, leave advanced HAL/tasking out.

## API (`Beginner_Board`)

| Entity | Role |
|--------|------|
| `Pin` (`0 .. 31`) | Pin index |
| `Pin_Mode_Kind` | `Input`, `Output`, `Input_Pullup` |
| `Pin_Level` | `Low`, `High` |
| `Pin_Mode` | Configure a pin |
| `Digital_Write` / `Digital_Read` | Drive / sample a pin |
| `Delay_Ms` / `Millis` | Simulated time for host tests |
| `Simulate_External` | Drive an input from the test harness |
| `Reset` | Clear simulator state |

`Digital_Write` has a precondition that the pin mode is `Output` (checked at run time with `-gnata`). The package body is an in-memory simulator; a future board port would swap the body only.

## Build & test

Requires GNAT (Ada 2022). No Alire.

```bash
make        # build + run V&V
make test   # same
make prove  # SPARK Level 2 (needs SPARK install)
make clean
```

Build flags used: `-gnatwa -gnat2022 -gnata` (warnings as attention, Ada 2022, assertion policy for contracts).

## SPARK

`SPARK_Mode` is On. `make prove` runs Level 2 (`cvc5`) against the simulator package. A future real-board body would re-prove separately; `Delay_Ms` here only advances the simulated `Millis` counter (no wall-clock sleep).

## License

MIT — see [LICENSE](LICENSE).

## LLM usage disclosure

AI assistance was used for this project.
