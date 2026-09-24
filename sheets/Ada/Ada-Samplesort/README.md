# Ada Samplesort Implementation

## Project Overview
This project provides a robust, strongly-typed implementation of the **Samplesort** algorithm in Ada. Samplesort is a divide-and-conquer sorting algorithm often utilized in parallel computing. It operates as a generalization of quicksort, picking multiple pivots via sampling to divide data into `p` buckets, which are then sorted independently. 

## Features
- **Strong Typing**: Implements specific `Data_Element` and `Data_Array` types to prevent implicit casting and ensure type safety.
- **Variant 1: Sequential Samplesort**: Traditional out-of-place bucketing processed on a single thread.
- **Variant 2: Parallel Samplesort**: Utilizes Ada Tasking (Shared Memory) to process bucket sorting concurrently, significantly improving speed on multi-core systems.
- **Variant 3: Oversampling Samplesort**: Samples a larger subset of the array to select statistically superior pivots, leading to more evenly distributed buckets.
- **Fallback Quicksort**: Custom, integrated Quicksort implementation used for base cases and bucket sorting.

## Testing
This repository relies on strict **Verification and Validation (V&V)** principles. The test philosophy strictly assumes the codebase is flawed, broken, or insecure. Tests pass only when this assumption is disproven.

The test suite validates the following categories:
- **Functional Correctness**: Proves the fundamental logic (sorting correctness, preservation of elements) against random, identical, and reverse-sorted data.
- **Boundary & Edge Cases**: Disproves assumptions that the algorithm crashes on 0-element arrays, 1-element arrays, or when `Num_Buckets > Data'Length`.
- **Parallel Safety**: Verifies that shared memory modifications via Ada Tasks do not result in race conditions or memory corruption.
- **Error Handling**: Verifies system reliability by ensuring inputs like `0` buckets gracefully raise `Invalid_Bucket_Count` rather than permitting Division by Zero or Segmentation Faults.
- **Performance/Stress Limits**: Disproves that the algorithm suffers stack overflows under larger dataset loads.

By thoroughly rejecting pessimistic assumptions, we prove the code reliably handles all strict system requirements expected of high-integrity Ada applications.

## Usage

### Compilation
The codebase uses a GNAT Project File alongside a traditional Makefile. 

To compile the codebase and tests, run:
```bash
make all
