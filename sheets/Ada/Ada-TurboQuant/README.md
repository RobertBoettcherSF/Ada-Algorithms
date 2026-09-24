# TurboQuant Ada Implementation

## Project Overview
This project implements the **TurboQuant** online vector quantization algorithm in Ada 2012. Originally proposed by Google Research for large language model (LLM) inference and KV cache compression, this data-oblivious algorithm compresses high-dimensional vectors while preserving structural boundaries. 

## Features
- **Strong Typing**: Implements custom strict types (`Real`, `Vector`, `Matrix`, `Sign_Vector`) to prevent silent memory violations.
- **Variant 1: TurboQuant_mse**: The base continuous k-means / Lloyd-Max variant optimized for Mean Squared Error compression.
- **Variant 2: TurboQuant_prod**: The dynamic variant optimized for unbiased inner-product estimation using 1-bit Quantized Johnson-Lindenstrauss (QJL) transforms on residual data.
- **Edge-Case Tolerance**: Fully bounded and mathematically robust handling of exact matrix matches and zero-residuals. 

## Testing
This codebase subscribes to strict Verification & Validation (V&V) principles for critical systems. The internal assumption is always pessimistic: *The code is considered defective until proven functionally correct.*

### What is verified:
- **Functional Correctness (Tests 1-5, 8-11):** Ensures operations like Euclidean Norm calculation, transposition, and structural dequantization work per specification limits.
- **Error Handling (Tests 6-7):** Deliberately passes mathematically invalid data (e.g., mismatched dimensions) to prove the exception layers catch domain violations safely.
- **Edge Cases (Tests 12-13):** Proves logic soundness even against 1x1 vector processing scales, ensuring the continuous k-means centroid mapping doesn't hit zero-division logic traps on exact centroid matches.

### Why it matters:
Quantization algorithms govern direct memory pipelines in production. These tests prevent catastrophic inference collapse by ensuring dimension bounds are strictly adhered to, proving mathematical operations are free of hidden constraints, and confirming structural integrity matches physical definitions. 

## Usage
The system is managed seamlessly via `make` using `gnatmake` directly at the root directory level.

### Compilation
```bash
# Compile via make
make all
