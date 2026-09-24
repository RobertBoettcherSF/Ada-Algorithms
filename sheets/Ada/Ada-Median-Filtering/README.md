# Median Filtering Algorithm in Ada

## Project Overview
This project provides a robust implementation of the Median Filtering algorithm. Median filtering is a non-linear digital filtering technique used to remove noise (particularly impulse or "salt-and-pepper" noise) from digital signals and images while preserving edges.

## Features
- **1D Median Filter**: Designed for processing signal arrays with configurable kernel sizes.
- **2D Median Filter**: Designed for image processing (or 2D matrices) using square kernels.
- **Boundary Handling**: Implements edge replication to ensure filter stability at the start/end of signals and edges of images.
- **Strong Typing**: Utilizes custom Ada array types to ensure type safety.
- **Exception Handling**: Explicitly handles invalid kernel sizes (e.g., even-sized kernels are prohibited for standard median calculation).

## Testing
The project includes a comprehensive test suite in `tests.adb` comprising 13+ test cases.

### Verification and Validation (V&V)
- **Functional Correctness**: Verified by testing noise removal capabilities (impulse noise), identity transformations (all uniform data), and boundary logic.
- **Robustness**: Verified by testing edge cases like empty arrays, 1x1 matrices, and large kernels.
- **Error Handling**: Validated that `Invalid_Kernel_Size` is raised when improper input is provided, preventing undefined behavior.

Tests follow a TDD (Test-Driven Development) philosophy: we assume code is faulty until proven correct by passing assertions.

## Usage

### Compilation
Ensure you have GNAT installed. To compile the project:
```bash
make
