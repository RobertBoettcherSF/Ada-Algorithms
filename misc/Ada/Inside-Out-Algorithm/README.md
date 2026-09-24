# Inside-Outside Algorithm (Ada 2023)

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of the **Inside-Outside algorithm**, a cornerstone dynamic programming algorithm for scoring and parameter estimation in Probabilistic Context-Free Grammars (PCFGs) mapped onto Chomsky Normal Form. The solution systematically unrolls expectation-maximization (EM) passes utilizing dynamic unconstrained matrices for *α* (Inside) and *β* (Outside) probabilities, making it optimal for machine learning tasks across natural language processing and bioinformatics architectures.

---

## Features

- **Inside Probability Estimation:** Computes the probability of generating arbitrary sequence spans explicitly starting from specific non-terminals.
- **Outside Probability Estimation:** Reverses the dynamic evaluation model to provide probabilities of partial sequences constrained by specific non-terminal derivation points.
- **Expectation-Maximization (EM) Step:** Integrates both Outside and Inside probability profiles, dynamically evaluating the sequence to iteratively tune grammar rules toward local maximum likelihood estimations.
- **Chomsky Normal Form PCFGs:** Operates on normalized forms requiring rules to exclusively decompose into unary terminal nodes or strict binary non-terminal tuples.
- **Strong Safety Contracts:** Subprogram preconditions and dynamic verification models using Ada contracts strictly block zero-probability expectation division and illegal state mutation.

---

## Usage

To evaluate the system, compile and execute the test harness, which instantiates a representative PCFG and walks through all internal computational iterations.

```bash
make test
```

**Expected Output:**

```plaintext
--- Inside-Outside Algorithm Test Suite ---
TEST 1 - Valid Grammar Identification
  PASS - 1.1 Grammar identifies as valid
  PASS - 1.2 Unary prob correct
  PASS - 1.3 Binary prob correct
...
===  39 passed,  0 failed ===
```

---

## Testing

The suite in `tests.adb` guarantees comprehensive Verification and Validation (V&amp;V):

- **Functional Correctness:** Ensures probabilities exactly reflect mathematical ground truths through precision equality limits (`Approx_Eq`).
- **Base &amp; Recursive Constraints:** Assures both length=1 base cases and combinatorial length=N iterations accurately accumulate probability masses exactly as standard structural theory mandates.
- **EM Correctness:** Identifies how expectation counts restructure probabilistic weights on unseen versus highly repeated symbols without skewing limits.
- **Fault Handling:** Identifies illegal operations (zero-likelihood expectation updates), trapping anomalies securely before math faults occur via `Computation_Error`.

---

## Building

**Prerequisites:**

- GNAT Ada Compiler (GCC suite) capable of compiling Ada 2022/2023 constructs.
- GNU Make.

To construct all binaries and clean up:

```bash
make all
make clean
```
