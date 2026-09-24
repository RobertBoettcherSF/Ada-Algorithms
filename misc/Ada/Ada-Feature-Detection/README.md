# Feature Detection (Computer Vision) in Ada

## Project Overview
This repository provides a strict, strongly-typed Ada implementation of Computer Vision Feature Detection algorithms based on fundamental paradigms documented on [Wikipedia's Feature Detection page](https://en.wikipedia.org/wiki/Feature_detection_(computer_vision)). 

The system analyzes an 8-bit grayscale 2D `Image` matrix to identify and classify distinct physical features in the data without relying on external computer vision dependencies.

## Features
The codebase implements the 4 major variants of feature extraction using custom convolution and mathematical kernels:
1. **Edge Detection**: Approximated via the 1st-derivative Sobel Operator (Gx/Gy gradient mapping).
2. **Corner Detection**: Approximated via a shifting-window Sum of Squared Differences (SSD) inspired by Moravec's variance operator.
3. **Blob Detection**: Approximated via a 2nd-derivative Laplacian kernel mapping regions of interest.
4. **Ridge Detection**: Approximated using a simplified principal curvature metric (Hessian matrix proxy).

## Testing
The repository is governed by strict **Verification & Validation (V&V)** principles. The test suite is built on a pessimistic assumption: *the code is incorrect until proven otherwise by mathematical and behavioral bounds tests*. 

The test suite consists of 13 separate assertion checks spread across 4 categories:
* **Category 1 (Bounds Safety)**: Verifies that image matrices too small for 3x3 kernels gracefully trigger an `Invalid_Image_Error` rather than causing undefined memory/Constraint errors. (Safety requirement).
* **Category 2 (False Positives)**: Submits fully flat images (all 0s or all 128s) to verify the mathematical logic mathematically yields 0 variance/response. (Correctness per requirements).
* **Category 3 (True Positives)**: Submits deterministic synthetic inputs (lines, points) guaranteeing specific feature geometries to validate that the respective kernel correctly maps them. (Use-case validation).
* **Category 4 (Logic & Constraints)**: Pushes algorithmic thresholds beyond maximums and intentionally limits output buffers to verify array overflow protection and threshold cut-offs. (Reliability).

These tests matter because feature extraction algorithms often feed critical autonomous systems; an undetected buffer overflow or false-positive geometry could result in erratic downstream decision-making.

## Usage

### Compilation
The project requires the GNAT Ada compiler. It uses a custom Makefile routing all object and binary files to isolated directories.
```bash
make all
