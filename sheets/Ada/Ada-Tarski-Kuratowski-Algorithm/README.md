# Tarski-Kuratowski Algorithm in Ada

## Project Overview
This repository provides a strongly-typed Ada implementation of the **Tarski-Kuratowski Algorithm**. Used in mathematical logic, descriptive set theory, and computability theory, this algorithm computes the upper bound for the complexity of a logical formula within the Arithmetical Hierarchy (First-Order logic over natural numbers) or the Analytical Hierarchy (Second-Order logic over functions/sets) by evaluating its quantifier prefix. 

## Features
- **Arithmetical Hierarchy Evaluator (`Evaluate_Arithmetical`)**: Parses prefixes to map formulas to $\Sigma^0_n$, $\Pi^0_n$, or $\Delta^0_0$.
- **Analytical Hierarchy Evaluator (`Evaluate_Analytical`)**: Handles formulas containing second-order quantifiers ($\Sigma^1_n$, $\Pi^1_n$, or $\Delta^1_1$), correctly absorbing first-order quantifiers as mathematically required.
- **Dynamic Bound Resolver (`Get_Upper_Bound`)**: Automatically detects the presence of higher-order quantifiers and routes the prefix sequence to the mathematically appropriate evaluator.
- **Quantifier Block Collapsing**: Automatically reduces consecutive identical quantifiers (e.g., $\exists \exists \forall$ evaluates properly as $\exists \forall$).
- **Strict Typing & Bounds**: Leverages Ada's strong record and enumeration typing to map abstract mathematics (Existential/Universal, Types) directly into compiler-checked constructs.

## Testing (Verification and Validation)
For software in critical or logical systems, correctness is non-negotiable. Our test suite (`tests.adb`) operates on strict Verification and Validation (V&V) principles:
- **Verification (Did we build the system right?)**: We assume our alternation counting logic and state-tracking are intrinsically flawed. The tests attempt to prove this pessimistic assumption by feeding inputs designed to break block-collapsing or sequence counts. 
- **Validation (Did we build the right system?)**: We ensure the algorithm adheres to external mathematical rules (e.g., in the Analytical hierarchy, first-order quantifiers *cannot* increment the $\Sigma^1_n$ level).

### What Each Test Category Verifies:
1. **Functional Correctness (Tests 1-6, 9-12):** Proves that permutations of quantifiers output the mathematically correct Class ($\Sigma$, $\Pi$) and Level ($n$). 
2. **Error Handling & Protection (Test 7):** Validates that routing a Second-Order constraint into a strict Arithmetical context correctly raises an `Invalid_Hierarchy_Prefix` exception, rather than silently computing a false bound.
3. **Edge Cases & Boundaries (Test 8, 15):** Ensures arrays of zero length do not crash and properly default to $\Delta_0$ (or $\Delta^1_1$ for analytical context). Tests complex block collapses where consecutive and alternating inputs attempt to overflow the parser.
4. **Integration (Test 13, 14):** Verifies the Dynamic Resolver operates flawlessly, seamlessly bridging the two implementations.

These tests guarantee reliability by covering all combinations of algorithmic branching, proving the code functions completely as intended against stringent pessimistic initial assumptions.

## Usage

### Compilation
The project utilizes a GNAT project file (`.gpr`) and a `Makefile` to cleanly isolate build artifacts while keeping source code in the root repository. 

Run the following command to compile:
```bash
make
