# Ada-PCIe-Transfer-Model

Educational Ada/SPARK **Level-2** sheet: a **host↔device transfer accountant**.

Records abstract transfers with `Size_Bytes`, `Alignment`, and `Direction`
(`H2D` / `D2H`), maintains running totals, and rejects misaligned or
over-budget requests. An optional simple `Bandwidth_Budget_Bytes_Per_Tick`
caps bytes recorded per accounting tick (`Advance_Tick` clears per-tick use).

This is **not** a PCIe controller, transaction-layer model, or vendor driver.
No proprietary NVIDIA/AMD/PCIe headers — clean-room educational sizes only.

## Build (no Alire)

Host **GNAT** + **gnatprove**. This repo does **not** use Alire.

```bash
make test
make prove   # level 2, cvc5, warnings/checks as errors
```

`make prove` sources `/home/box/deps/spark/env.sh` (or put `gnatprove` on `PATH`).

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
The Ada/SPARK sources, contracts, tests, and proof results were checked with
GNAT and gnatprove on the host toolchain.

## License

MIT — see [LICENSE](LICENSE).
