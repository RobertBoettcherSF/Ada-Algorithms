# Level Set Method in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Level Set Method**. The level set method is a numerical analysis technique for shapes and spaces, allowing one to perform numerical computations involving curves and surfaces on a fixed Cartesian grid without having to parameterize these objects. It is highly effective for tracking moving interfaces (e.g., fluid dynamics, computer vision, and combustion).

## Features
The following variants and core algorithms from the level set literature are fully implemented:
* **Basic Level Set Update:** Solves the standard level set equation $\frac{\partial \phi}{\partial t} + F |\nabla \phi| = 0$ using an explicit Euler time integration and Godunov's upwind scheme.
* **Narrow Band Method:** An optimized variant that only performs calculations on grid points immediately adjacent to the zero level set interface ($|\phi| \leq \text{Band\_Width}$), drastically reducing computational load.
* **Reinitialization Algorithm:** Implements the Sussman equation to reconstruct the Signed Distance Function (ensuring $|\nabla \phi| = 1$) without drastically displacing the location of the zero-interface.
* **Neumann Boundary Conditions:** Stabilizes equations at the edges of the 2D grid matrix.

## Testing
This codebase operates under strict **Verification and Validation (V&V)** principles, typical for high-integrity Ada systems. A pessimistic assumption is made that code is functionally incorrect until tests disprove this via explicit assertions. 

The test suite categorizes verifications into:
1. **Functional Correctness (Tests 1-5, 14):** Verifies the actual mathematics. E.g., positive speeds expand the interface, negative speeds contract it, and Reinitialization restores scalar gradients to 1.0. This validates that equations match physical reality.
2. **Performance Constraints (Tests 7-8):** Validates the "Narrow Band" optimization ensures far-field values are entirely ignored, guaranteeing $\mathcal{O}(k)$ time complexity vs $\mathcal{O}(N^2)$.
3. **Edge Cases (Tests 6, 13):** Ensures zero values (time steps, speed variables) do not mutate state via floating-point errors.
4. **Error Handling & Robustness (Tests 10-12):** Defends against catastrophic failures such as undersized grids (matrix bounds) or out-of-range negative time steps. Validates stability at extreme array bounds (Boundary Conditions).

These tests matter because critical numerical systems easily succumb to subtle floating-point drift, grid divergence, or index-out-of-bound errors. Disproving these failures assures reliability and safety.

## Usage

### Compilation
The project utilizes `gnatmake` and a custom GNAT project file (`.gpr`). A Makefile handles directory setup.

To compile both the application and the test suite:
```bash
make all
