# Ada-sjn
Ada implementation of the Shortest Job Next (SJN) scheduling algorithm, which is also commonly referred to as Shortest Job First (SJF)

## Overview

This project implements two variants of the SJN/SJF scheduling algorithm:
1. **Non-Preemptive SJN**: Once a job starts executing, it runs to completion without interruption
2. **Preemptive SJN (Shortest Remaining Time First)**: The scheduler can preempt a running job if a new job arrives with a shorter remaining burst time

## Running the Simulation

To compile and run the main simulation:

```bash
# Using gprbuild (recommended)
gprbuild -P sjn_scheduler.gpr
./sjn_main

# Or using gnatmake
gnatmake sjn_main.adb
./sjn_main
```

## Running Tests

The project includes a comprehensive test suite with 53+ tests organized into 5 categories:

### Test Categories:

1. **Basic Functionality Tests** (8 tests)
   - Single job execution
   - Two job scenarios
   - Verification of completion times, waiting times, and turnaround times

2. **Edge Case Tests** (8 tests)
   - Empty job arrays
   - Jobs arriving at the same time
   - Zero burst time jobs
   - Jobs arriving after previous jobs complete

3. **Correctness Tests** (7 tests)
   - Verification of optimal scheduling
   - Comparison between preemptive and non-preemptive variants
   - Validation of average waiting times

4. **Property-Based Tests (Invariants)** (13 tests)
   - Turnaround time = Waiting time + Burst time
   - Completion time = Arrival time + Turnaround time
   - All jobs must complete
   - Waiting time cannot exceed completion time

5. **Falsifiable Assumptions** (3 tests)
   - Non-preemptive and preemptive produce different results (PROVEN FALSE)
   - SJN always gives zero waiting time (PROVEN FALSE)
   - Preemptive is always faster than non-preemptive (PROVEN FALSE)

To run the tests:

```bash
# Using gprbuild (recommended)
gprbuild -P test_sjn.gpr
./sjn_tests

# Or compile directly
gnatmake sjn_tests.adb
./sjn_tests
```

### Test Output

The test suite provides detailed output showing:
- Each test result (PASS/FAIL)
- Expected vs actual values for assertions
- Summary statistics at the end

Example output:
```
===================================================================
SJN Scheduling Algorithm Test Suite
===================================================================

=== TEST CATEGORY 1: Basic Functionality ===

[PASS] Test 1.1: Single job completes
[PASS] Test 1.2: Single job completion time is burst time (Expected:  5, Got:  5)
...

===================================================================
TEST SUMMARY
===================================================================
Total Tests:  50
Passed:  53
Failed:  0

ALL TESTS PASSED!
===================================================================
```

## Project Structure

- `sjn_main.adb`: Main implementation with both scheduling variants
- `sjn_scheduler.ads`: Procedure specification
- `sjn_scheduler.gpr`: GPR project file for main program
- `sjn_tests.adb`: Comprehensive test suite
- `test_sjn.gpr`: GPR project file for tests
- `README.md`: This file
- `LICENSE`: License information

## Algorithm Details

### Non-Preemptive SJN
- At each scheduling point, selects the job with the shortest burst time among arrived jobs
- Once selected, the job runs to completion
- Tie-breaker: First-come, first-served for jobs with equal burst times

### Preemptive SJN (SRTF)
- At each time unit, selects the job with the shortest remaining time among arrived jobs
- Can preempt currently running jobs if a shorter job arrives
- Tie-breaker: First-come, first-served for jobs with equal remaining times

## Requirements

- GNAT (GNU Ada Translator) - part of GCC
- gprbuild (for project file support)

On Debian/Ubuntu:
```bash
sudo apt-get install gnat gprbuild
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
