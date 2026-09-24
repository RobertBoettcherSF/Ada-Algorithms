# Ada-NEF-Neurorobotics-Core

Educational Ada (2022) packages that implement the *ideas* behind the white-box
rover control laws and a minimal NEF-style function approximator from:

> DeWolf, Jaworski, Eliasmith — *Nengo and low-power AI hardware for robust,
> embedded neurorobotics*, [arXiv:2007.10227v2](https://arxiv.org/abs/2007.10227).

This is a **clean-room** Ada rewrite of the published equations and NEF concepts.
It does **not** copy ABR/nengo Python sources.

## Four challenges (from the abstract)

The paper identifies four primary challenges for robust embedded neurorobotics:

1. **Environment / sensor interfacing** — infrastructure to talk to simulators and hardware.
2. **Task-specific sensory processing** — e.g. vision DNNs converted toward neuromorphic backends.
3. **Robust, explainable control** — white-box circuits (NEF) with known functions and guarantees.
4. **Compile to target hardware** — same model on CPU/GPU/Loihi and related backends.

This repository focuses on challenge **(3)** in miniature: exact control laws (§3.3)
plus a tiny educational NEF ensemble — not a full Nengo stack.

## What is included

| Package | Role |
|---------|------|
| `Rover_Control` | Exact eqs. (1)–(2): clipped-distance acceleration and `Arctan2` steering |
| `LIF_Neuron` | Discrete Euler leaky integrate-and-fire (V, spike, reset) |
| `NEF_Ensemble` | N=32 rate neurons, unit-circle encoders, least-squares decoders for acceleration |
| `tests.adb` | V&V fixtures: control, LIF spike/silence, NEF MSE / decode vs reference |

## What is *not* included

- No Mujoco / physics simulator
- No Loihi / NengoLoihi / neuromorphic compile path
- No vision CNN / Keras / NengoDL
- No Alire crate; no `gnatprove` Level-2 proofs (Ada + `-gnata` V&V suite only for now)

Gain defaults (`Ka`, `Kp`) are documented parameters on `Rover_Control` (paper leaves them free).

## Build & test

Requires GNAT (e.g. FSF GNAT 14+). No Alire.

```bash
make test
```

Uses `gnatmake -gnatwa -gnat2022 -gnata`.

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
All Ada sources were checked by building and running `make test` with host GNAT.

## License

MIT — see [LICENSE](LICENSE).
