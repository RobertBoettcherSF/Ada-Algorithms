# Texas Medication Algorithm Project (TMAP) - Ada Implementation

## Project Overview
This repository contains an Ada implementation of the Texas Medication Algorithm Project (TMAP). TMAP was a psychiatric medical algorithm utilizing decision trees to systematize the treatment of Major Depressive Disorder (MDD), Schizophrenia, and Bipolar Disorder. This implementation models the algorithm as a robust Finite State Machine (FSM), mapping patient responses (Positive, Negative, Intolerable, Partial) to dynamic stage advancements and precise pharmacological recommendations (e.g., SSRIs, Clozapine, ECT).

## Features
*   **Three Primary Disease Pathways:** Full algorithmic trajectories for MDD, Schizophrenia, and Bipolar Disorder.
*   **Sequential Stage Mapping:** Implementation of Stages 1 through 6, automatically advancing based on programmatic response evaluation.
*   **Algorithmic Precision:** Key pharmacological rules (e.g., prescribing Clozapine for Stage 3 Schizophrenia, ECT for late-stage MDD) are strictly encoded.
*   **Boundary Enforcement:** Strict typed limitations mapping Maintenance (success state) and Refractory (treatment-resistant) boundaries, leveraging Ada exceptions for invalid FSM transitions.
*   **Flat Directory Structure:** Simple, centralized architecture designed for rapid compilation and review.

## Testing
This project utilizes a pessimistic Verification & Validation (V&V) philosophy. The test suite is designed under the assumption that the codebase contains failure points; a `PASS` state proves the initial assumption of failure to be strictly false, confirming architectural integrity.

**What the tests verify:**
1.  **Functional Correctness:** Ensures accurate drug mapping per TMAP guidelines (e.g., Lithium for Bipolar initiation, SSRI for MDD Stage 1).
2.  **Error Handling:** Verifies that out-of-bounds states (attempting to medicate Unspecified diseases, advancing beyond the Refractory stage) correctly trigger Ada exceptions (`Unspecified_Disease`, `Refractory_State_Reached`).
3.  **Edge Cases:** Confirms that patient relapses from a "Maintenance" state properly restart the evaluation FSM, and that partial responses safely advance the treatment matrix.
4.  **State Logic & Performance:** Ensures state mutations happen safely without memory corruption or unauthorized data leakage across disease types.

**Why these tests matter:**
In critical systems—particularly algorithms simulating medical or diagnostic pathways—Verification (building the system right) and Validation (building the right system) are paramount. This suite ensures safety, predictability, and compliance with intended deterministic behavior. By forcing the code into bounded edge-cases, we guarantee reliability against unexpected execution states.

## Usage

### Compilation
The project utilizes a GNAT Project file (`tmap.gpr`) combined with a `Makefile` for automated build management.

To compile the binaries:
```bash
make build
