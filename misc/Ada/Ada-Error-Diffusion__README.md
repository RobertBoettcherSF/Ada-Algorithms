# Error Diffusion Algorithms (Ada Implementation)

## Project Overview
This repository contains a complete, strongly-typed Ada implementation of various **Error Diffusion** algorithms used in image processing (specifically halftoning/quantization). Error diffusion minimizes visual artifacts by distributing quantization errors (the difference between an original pixel and its binary representation) to neighboring unvisited pixels based on specific mathematical kernels. 

## Features
The codebase provides a generic diffusion engine capable of handling **all variants** of the error diffusion kernels mentioned in classical literature (and Wikipedia), including:
*   **Floyd-Steinberg** (Standard 1D diffusion)
*   **Jarvis, Judice, and Ninke (JJN)**
*   **Stucki** 
*   **Atkinson** (Partial error diffusion)
*   **Burkes**
*   **Sierra Family** (Sierra3, Two-Row Sierra, and Sierra Lite)

It safely processes dynamic matrix sizes and automatically clips/clamps values to avoid floating-point/constraint overflow.

## Testing
This project strictly adheres to rigorous Verification and Validation (V&V) principles standard for safety-critical systems. The test suite operates on a **pessimistic assumption philosophy**: it assumes the codebase is non-functional and relies on tests to assertively prove it works. 

### What the tests verify:
1.  **Functional Correctness:** Verifies accurate math across all kernel matrices (weight distribution, kernel bounds).
2.  **Error Handling & Boundaries:** Ensures edge cases like empty matrices (`0x0`) correctly throw handled `Invalid_Image_Error` exceptions rather than core-dumping.
3.  **Edge Cases & Out-Of-Bounds:** Asserts that pixels on the extreme right and bottom edges of an image safely drop external error data rather than causing buffer overflows or segmentation faults.
4.  **Performance via Clamping:** Confirms that extreme threshold jumps (cascading max errors) remain constrained between `0.0` and `255.0` via internal clamping mechanisms.

### Why these tests matter:
In systems programming, ensuring reliability is paramount. A malformed halftoning array could crash an embedded printer controller or memory layout. By verifying mathematical boundaries, type safety, and error cascading limits, the test suite guarantees software correctness per standard V&V mandates. A "PASS" indicates the initial assumption of failure has been definitively disproven.

## Usage

### Compilation
The project uses GNAT and standard Makefiles. To build the project, run:
```bash
make all
