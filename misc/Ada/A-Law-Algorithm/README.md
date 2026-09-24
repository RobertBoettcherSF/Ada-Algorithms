# A-Law Companding Algorithm

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **A-law algorithm**, a standard companding technique used primarily in European 8-bit PCM digital communication systems. The library allows raw audio signal dynamics to be compressed for efficient low-bandwidth transmission and subsequently expanded back to their original form.

## Features
*   **Strong Typing Framework:** Safety-critical constraint limits enforcing `Normalized_Sample (-1.0..1.0)`, `PCM_Sample (-4096..4095)`, and `A_Law_Byte (0..255)`.
*   **Continuous Domain Variants:** Pure mathematical implementation of A-law (A = 87.6) for floating-point encoding and decoding across linear/logarithmic bounds.
*   **Discrete Domain Variants (G.711 PCM):** Hardware-accurate 8-bit mapping for 13-bit signed integer signals.
*   **Even-bit Toggle Accuracy:** Correctly implements standard G.711 `0x55` XOR transmission toggling for DC bias and transition density optimizations.
*   **Robust Edge Handling:** Prevents `Constraint_Error` crashes using safe signal magnitude clamping (`max 4095`) out-of-the-box.

## Testing & V&V Principles
Our methodology strictly adheres to high-reliability Verification and Validation (V&V) standards. We test under the pessimistic assumption that the code is fundamentally broken, allowing the software to 'prove' itself correct through exhaustive constraint boundary breaking attempts. 

**What the test categories verify:**
1.  **Functional Correctness:** Asserts piecewise equation breakpoints (e.g., $1/A$ threshold shifts) correctly transition from linear models to log models without producing NaN or out-of-bounds metrics. 
2.  **Standards Validation (G.711):** Checks deterministic hexadecimal byte outputs based on ITU-T G.711 requirements (e.g., `0` input *must* encode precisely to `0xD5`). 
3.  **Boundary & Edge Cases:** Inputs maximum peak values (`1.0`, `4095`) and minimum negative edge ranges (`-1.0`, `-4096`) to ensure the types and calculations cleanly clamp rather than throw fatal exceptions.
4.  **Identity / Reversibility:** Evaluates the inevitable data loss of integer-based signal quantization and asserts that absolute signal delta (`Abs(Decode(Encode(X)) - X)`) remains correctly constrained within its mathematically expected step-scale limit (e.g., bounds $< 2$ deviation for low magnitudes, $< 16$ for high magnitudes).

Testing proves reliability by simulating physical audio hardware conversions mathematically inside memory boundaries before deployment. 

## Usage

### Compilation
The project utilizes `gnatmake` driven entirely through a `Makefile`. No messy source folders. To build the test/runner binary:

```bash
make all
