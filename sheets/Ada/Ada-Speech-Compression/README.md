# Speech Encoding Algorithm Implementations

## Project Overview
This project provides an Ada-based implementation of fundamental speech encoding algorithms used in digital telephony and audio compression. The repository covers core waveform coding techniques derived from the G.711 standard and differential coding concepts.

## Features
The codebase implements the following speech encoding variants:
*   **μ-law (Mu-Law) Companding:** Preemptive encoding/decoding technique standard in North America and Japan, mathematically compressing 16-bit linear PCM dynamic range into an 8-bit equivalent logarithmic space.
*   **A-law Companding:** European standard equivalent, utilizing both linear (for small signals) and logarithmic (for large signals) quantization regions.
*   **Differential Pulse-Code Modulation (DPCM):** A predictive coding variant that encodes the mathematical difference between consecutive audio samples, leveraging temporal redundancy in speech.

## Testing
This project embraces rigorous Verification and Validation (V&V) principles standard in safety-critical systems. 

**V&V Philosophy:**
Our test suite approaches the codebase with extreme pessimism, inherently assuming that the code is *broken, non-functional, and handles memory poorly*. A test yielding a `PASS` actively disproves this pessimistic assumption by empirically demonstrating correct behavior.

**What is Verified:**
1.  **Functional Correctness:** Verifies that zero-crossings and algorithm maximums remain anchored (0.0 → 0.0, 1.0 → 1.0). Validates mathematical reversibility (`Decode(Encode(x)) == x`).
2.  **Edge Cases:** Boundary regions in the A-law algorithm (ensuring correct routing between the linear division and the logarithmic calculation).
3.  **Error Handling (Robustness):** Confirms structural safety guarantees—feeding invalid boundaries (>1.0) or empty buffers strictly triggers isolated Ada Exceptions (`Invalid_Sample_Error`, `Empty_Buffer_Error`) rather than causing segmentation faults.
4.  **Sequential Integrity:** DPCM array tests guarantee that state accumulation does not drift across sequential data.

**Why these tests matter:**
In telecommunications, silent calculation drift results in severe audio artifacting. Buffer mismanagement leads to buffer overruns (CWE-119). By applying strict unit-testing in Ada, we enforce safety guarantees at compile-time and logic correctness at runtime.

## Usage

### Compilation
The project utilizes the GNAT toolchain and can be built directly via the included Makefile. Ensure you have `gnatmake` installed.

```bash
# Compile and build the executable
make all
