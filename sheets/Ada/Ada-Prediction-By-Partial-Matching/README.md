# Prediction by Partial Matching (PPM) Algorithm

## Project Overview
This repository provides a mathematically rigorous Ada implementation of the Prediction by Partial Matching (PPM) algorithm modeling phase. PPM is an adaptive statistical data compression technique based on modeling contextual occurrences and synthesizing probability bounds. The implementation maps and clusters string history dynamically into a suffix Trie to accurately predict the likelihood of the succeeding symbol sequence. 

## Features
- **Strongly Typed Bounded Context Trie**: Dynamically routes and records hierarchical context occurrences without memory fragmentation.
- **Multiple Estimation Variants**: Integrates the standard zero-frequency mathematical estimators specified in PPM literature:
  - **PPM-A (Laplace)**: Uses a static pseudo-count.
  - **PPM-B**: Assigns escape ratio mapped strictly to unique symbol observations.
  - **PPM-C**: Utilizes advanced weighted probability smoothing.
  - **PPMd**: Adjusts probability uniquely per observation based on continuous ratios.
- **Dynamic Models**: Supports configuration for limited contextual dependencies (e.g. `PPM(3)`) or dynamically unbound scaling (`PPM*`). 
- **Blended Arithmetic Distributions**: Synthesizes output from the context trie, delivering precise float probabilities essential for coupling with an arithmetic coding layer.

## Testing (Verification & Validation)

**Philosophy**: In critical systems engineering, the default assumption dictates that implemented software inherently harbors mathematical or pointer-related defects. The verification suite is aggressively designed to try and enforce division by zero, float drift out of standard bounds, and memory leakage. A "PASS" designation indicates these initial pessimistic assumptions were actively disproven.

- **Functional Correctness**: Mathematical verification ensures functions like `Estimate_Laplace` and `Estimate_PPMd` correctly distribute float bounds mathematically. Test `6.2` strictly checks that the mass of our output array evaluates securely to `1.0`. A violation here renders compression algorithms entirely un-decodable. 
- **Error Handling**: Context tables correctly absorb uninitialized inquiries by backing off sequentially downwards directly to a safe `-1` order limit mapping without throwing numeric `Constraint_Errors`.
- **Edge Cases**: Validates identical repeated sequential operations versus fully unique ingestions to guarantee Trie mappings maintain isolation and accuracy across boundaries. 
- **Performance**: Safely sweeps nodes directly from dynamically bound depths without introducing trailing dangling pointers. 

## Usage

### Compilation Instruction
Ensure GNAT is natively installed on your command line interface. A structured `Makefile` is bundled within the root directory.

```bash
make
