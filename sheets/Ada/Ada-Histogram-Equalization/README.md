# Histogram Equalization Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Histogram Equalization algorithm, used to enhance contrast in digital images. It includes both Global Histogram Equalization and a tile-based Adaptive variant.

## Features
*   **Global Histogram Equalization**: Standard contrast stretching using the full image CDF.
*   **Adaptive Histogram Equalization (AHE)**: Tile-based variant for localized contrast improvement.
*   **Strong Typing**: Uses custom Ada types (`Intensity`) to prevent out-of-bounds pixel values.
*   **Robustness**: Explicit exception handling for edge cases like empty images.

## Testing
The test suite assumes the implementation is potentially broken and executes 13+ assertions to disprove this.
*   **Functional Correctness**: Ensures mathematical normalization (0-255 range).
*   **Error Handling**: Validates that empty inputs trigger `Empty_Image_Error`.
*   **Edge Cases**: Checks 1x1 matrices, uniform intensity images, and extreme contrast inputs.
*   **V&V Principles**: These tests verify requirements (Correctness) and validate intended use (Robustness), ensuring the software is reliable for critical systems.

## Usage

### Compilation
Ensure you have the GNAT compiler installed. Run from the root directory:
```bash
make
