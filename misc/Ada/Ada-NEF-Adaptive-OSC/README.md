# Ada-NEF-Adaptive-OSC

Educational Ada (2022) packages for a **joint-space PD** baseline plus a
**context-sensitive adaptive residual** torque — the arm-control half of the
mobile-manipulator story whose base/rover half lives in
[Ada-NEF-Neurorobotics-Core](https://github.com/RobertBoettcherSF/Ada-NEF-Neurorobotics-Core).

Ideas follow DeWolf, Jaworski, Eliasmith — *Nengo and low-power AI hardware for
robust, embedded neurorobotics*,
[arXiv:2007.10227](https://arxiv.org/abs/2007.10227) **§4** (adaptive arm
control: OSC + neural adaptive residual / PES-style online learning).

This is a **clean-room** Ada rewrite of the *published intuition* only.
It does **not** copy ABR/nengo Python sources, and it is **not** a full
operational-space dynamics stack.

## Motivation (wheels + arms)

Service mobile manipulators combine a wheeled base with one or more arms.
The companion repo covers white-box rover steering/drive laws; this repo covers
the complementary educational story: a tiny PD torque law plus an online
adaptive residual that learns to cancel unmodelled bias (e.g. an unexpected
payload) in a **host simulation** — without vendor product names as products.

## What is included

| Package | Role |
|---------|------|
| `OSC_PD` | 2-DOF **joint-space** PD: `τ = Kp·e + Kd·ė` (+ optional constant gravity/bias stub) |
| `Adaptive_Residual` | Bounded features `φ(q,qd)` (M=5), LMS/PES-like `Δw ∝ η·e·φ`, `τ_adapt = W·φ`, weight/rate bounds |
| `Plant_Sim` | Discrete Euler double-integrator plant + constant disturbance for closed-loop V&V |
| `tests.adb` | PD step response; adaptive vs PD under bias; zero-error → near-zero update |

Total torque: **`τ = τ_PD + τ_adapt`**.

## Educational vs real OSC / dynamics

| This sheet | Real OSC / paper stack |
|------------|-------------------------|
| Joint-space PD on a 2-DOF double integrator | Operational-space control with Jacobian, inertia, Coriolis, real multi-DOF arms |
| Bounded bias + joint/velocity features (M=5), dense LMS | NEF ensemble activities + PES decoders (often on neuromorphic hardware) |
| Host Euler V&V, `-gnata` assertions | Physical arms, Loihi on-chip learning, power/latency benchmarks |
| No Alire / no `gnatprove` L2 yet | Production robotics + formal methods as future work |

Gravity compensation here is a **constant bias vector stub**, not a full
rigid-body gravity model.

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
