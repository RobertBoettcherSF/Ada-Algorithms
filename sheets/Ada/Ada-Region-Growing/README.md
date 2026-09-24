# Ada Region Growing Image Segmentation

## Project Overview
This repository contains an Ada implementation of the **Region Growing** algorithm, an image segmentation technique used extensively in computer vision and medical image processing. The module operates on 2D arrays mapping numerical intensities and constructs regions by checking spatial proximity and intensity similarities.

## Features
The implementation covers all key variations of the region growing logic based on standard morphological algorithms:
- **Seeded_Local:** Grows regions starting from predefined seed coordinates by comparing neighboring pixels to the localized accepted pixel values.
- **Seeded_Average:** Dynamically maintains a running intensity mean of the segmented region. Neighbors are added based on their variance from the overall growing structure, rather than just local neighbors.
- **Unseeded (Automatic Segmenter):** Iterates autonomously across the whole image, generating implicit seeds to cluster all pixels into discrete regions, resulting in an integer Map representation.
- **Connectivity:** Supports both `Four_Connected` (Von Neumann neighborhood) and `Eight_Connected` (Moore neighborhood) operations.

## Testing (Verification & Validation)
This project enforces strong Verification & Validation (V&V) standards critical to reliable system engineering in Ada. The provided test suite operates under a strict philosophy: **"Assume the code is broken until proven otherwise."**

### What the test categories verify:
1. **Functional Correctness (Tests 1, 2, 8-10):** Ensures that the algorithm accurately follows mathematical constraints (threshold adherence) and segments expected regions correctly.
2. **Error Handling (Test 3):** Validates that exceptions (like `Invalid_Seed_Error`) are safely trapped and raised when hardware or data input faults provide bad coordinates.
3. **Edge Cases (Tests 4, 11-13):** Stretches data types across zero bounds (empty seeds), infinite thresholds, highly asymmetric 1D arrays, and 1x1 image blocks.
4. **Connectivity Mechanics (Tests 5):** Proves logic distinctions between processing orthogonal vs diagonal neighbors.

### Why these tests matter:
In critical systems (such as medical imaging where this algorithm is commonly deployed), silent failures or memory boundary overruns can lead to incorrect diagnoses. Using V&V testing confirms safety, establishes operational boundaries, and prevents undefined behaviors like constraint errors in multi-dimensional arrays. By deliberately passing adverse inputs, we establish robust operational reliability.

## Usage

### Compilation Instructions
The software relies on the GNAT Ada compiler. It uses a standard `.gpr` structure and `Makefile` abstraction.

To compile the project:
```bash
make all
