# Verlet Integration in Ada

## Project Overview
This repository implements the **Verlet integration** algorithm in Ada, widely used to calculate trajectories of particles in molecular dynamics simulations and computer graphics. It provides a highly stable numerical method for integrating Newton's equations of motion.

## Features
- **Basic Verlet Integration:** Computes next positions based on current and previous coordinates without explicitly solving for velocities. 
- **Velocity Verlet Integration:** Computes position, explicitly tracks velocity in phase space, and integrates acceleration over the current and next time step.
- **Leapfrog Integration:** Stormer's method variant that calculates positions and velocities at interleaved time points.
- **Math Vector Library:** Native robust 3D vector arithmetic mapping operator overloading (`+`, `-`, `*`, `/`) with safety checks.

## Testing
This codebase is rigorously tested based on rigorous Verification & Validation (V&V) principles to ensure the algorithms correctly model kinematic physics without floating-point catastrophic failures or math rule violations.

We operated on the **Pessimistic Assumption**: "Code is broken by default, and a test only PASSES when it actively disproves that failure assumption."

### What Each Test Category Verifies
1. **Functional Correctness (Kinematics):** Verifies that for constant acceleration, the integrators mathematically obey the exact formula $x(t) = x_0 + v_0 t + \frac{1}{2} a t^2$. 
2. **Error Handling (Safety):** Verifies that division by zero or backward-time integration (negative delta-time $\Delta t$) safely halts the system (raising `Constraint_Error` or `Invalid_Delta_Time`).
3. **Edge Cases:** Evaluates conditions like zero acceleration (inertia tracking), tiny floating-point values where `Are_Close()` epsilon bounds apply.
4. **Data Integrity:** Ensures caches (like previous position in Basic Verlet) aren't prematurely mutated before calculations complete.

### Why these Tests Matter
For critical systems (e.g., aerospace, physics simulation engines), accumulating integration errors or handling unverified negative time steps can cause catastrophic divergence. These tests prove the mathematical guarantees of energy-conservation specific to symplectic integrators (like Verlet).

## Usage
Ensure you have the GNAT Ada toolchain installed.

### Compilation
Everything compiles directly from the root utilizing `make` and the `.gpr` file.
```bash
# Compile all files
make all

# Clean objects and binaries
make clean
