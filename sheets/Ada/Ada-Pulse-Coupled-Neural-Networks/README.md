# Pulse-Coupled Neural Networks (PCNN) in Ada

---

## Project Overview

This project provides a robust, strongly-typed, and complete Ada 2023 implementation of **Pulse-Coupled Neural Networks (PCNN)**, algorithms widely used in image processing, segmentation, and feature extraction. Inspired by the visual cortex of mammals, PCNNs use linked differential equations modeling feeding compartments, linking compartments, and dynamic internal thresholds to emit synchronous pulses.

---

## Features

- **Standard PCNN:** Implements the complete recurrent equations incorporating feeding temporal decay, neighbor feeding fields (M-kernel), and linking fields (W-kernel).
- **Simplified / Unit-Linking PCNN:** Implements the computation-saving variant heavily used in image segmentation contexts, bypassing feeding decay by equating the feeding compartment directly to the stimulus.
- **Strongly Typed Dimensions:** Replaces bare floats and integers with problem-specific types (`Real`, `Dimension`, `Offset`) enforcing strict coordinate systems and type safety.
- **Contract-Based Validation:** Uses Ada 2012+ Aspects (`Pre`, `Post`) to strictly bind stimulus dimensions to state dimensions, safely catching matrix alignment errors.

---

## Building

To build this project, you will need the GNAT Ada compiler. This codebase leverages Ada 2012/2022/2023 conventions.

Run the provided Makefile from the directory:

```bash
make
```

---

## Testing

This project lacks a `main.adb` because the executable test suite dynamically doubles as the usage example for integrating PCNNs.

Execute the testing suite with:

```bash
make test
```

**Test Coverage Categories:**

- **Initialization &amp; Constraints:** Proves grid dimensions constrain variables successfully.
- **Edge Behavior:** Bounds-checks convolution helpers at grid corners, edges, and single cells.
- **Functional Correctness:** Asserts numerical accuracy across integration steps for equations F, L, U, Theta.
- **Exception Handling:** Deliberately injects disjoint array types into iterators and confirms graceful failure paths catching `Dimension_Mismatch`.

---

## Usage

Include the `pulse_coupled_networks` package in your `.gpr` file.

```ada
with Pulse_Coupled_Networks; use Pulse_Coupled_Networks;

-- 1. Create your state matching your image or dataset resolution
State : PCNN_State := Create_State (Rows => 256, Cols => 256, Init_Theta => 1.0);

-- 2. Iterate network against your normalized pixel weights (Stimulus)
Iterate_Simplified (State, Stimulus, Params, Cross_Kernel);

-- 3. The resulting binary image/segmentation is now in State.Y
```
