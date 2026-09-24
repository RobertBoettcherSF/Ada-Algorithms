# SRT Scheduling Algorithm - Test Suite

## Overview

This directory contains comprehensive tests for the Shortest Remaining Time (SRT) scheduling algorithm implementation. The tests are designed to:

1. **Make explicit assumptions** about what the code should do
2. **Test different scenarios** and edge cases
3. **Prove assumptions wrong** when they are incorrect

## Test Categories

### Category 1: Basic Functionality Tests (Tests 1-3)
- Single process completion
- Preemptive mode prioritization
- Non-preemptive mode behavior

### Category 2: Edge Cases (Tests 4-7)
- Processes arriving at the same time
- Processes with same burst time (tie-breaker by ID)
- Sequential process execution
- CPU idle time handling

### Category 3: Context Switch Overhead (Tests 8-9)
- Zero context switch penalty
- Non-zero context switch penalty
- Impact on completion times

### Category 4: Waiting and Turnaround Time Validation (Tests 10-12)
- Turnaround time calculation (Completion - Arrival)
- Waiting time calculation (Turnaround - Burst)
- First process waiting time

### Category 5: Tests Proving Wrong Assumptions (Tests 13-15)
- **WRONG ASSUMPTION**: All processes complete at arrival + burst
  - **REALITY**: Preemption causes delays
- **WRONG ASSUMPTION**: Non-preemptive SJN is always faster than SRT
  - **REALITY**: SRT has lower average waiting time
- **WRONG ASSUMPTION**: Context switch penalty doesn't affect results
  - **REALITY**: It does affect completion times

### Category 6: Algorithm Correctness (Tests 16-18)
- Validate the example from the main code (Preemptive SRT)
- Validate the example from the main code (Non-Preemptive SJN)
- Validate context switch example

## Total Tests: 18

All tests exceed the requirement of 12+ tests.

## Running the Tests

### Option 1: Using the Shell Script (No Ada Compiler Required)

The shell script contains conceptual tests that validate the logic:

```bash
chmod +x test_srt_algorithm.sh
./test_srt_algorithm.sh
```

This will run 20+ tests that validate the assumptions and logic of the SRT algorithm.

### Option 2: Using the Ada Test Runner (Requires Ada Compiler)

To compile and run the Ada test suite:

```bash
# Make sure you have an Ada compiler installed (gnat, gnatmake, or gprbuild)

# Compile the test runner
gnatmake test_runner.adb -o test_runner

# Run the tests
./test_runner
```

Or using gprbuild:

```bash
# Create a project file or use the existing one
# Then compile and run
gprbuild -P ../srt_simulation.gpr test_runner.adb
./test_runner
```

## Test Output

Both test runners will output:
- Individual test results (PASS/FAIL)
- Detailed error messages for failed tests
- Summary with total tests, passed, and failed counts

## Expected Results

All tests should pass if the SRT algorithm is implemented correctly. If any tests fail, it indicates:

1. A bug in the algorithm implementation
2. An incorrect assumption about the algorithm's behavior
3. A mismatch between expected and actual results

## Adding New Tests

To add new tests:

1. **For shell script tests**: Add new test functions in `test_srt_algorithm.sh`
2. **For Ada tests**: Add new test blocks in `test_runner.adb`

Each test should:
- Have a clear name describing what it tests
- Make explicit assumptions
- Include assertions with expected values
- Be designed to potentially fail if assumptions are wrong

## Test Design Philosophy

The tests follow these principles:

1. **Explicit Assumptions**: Each test clearly states what it assumes about the algorithm
2. **Multiple Perspectives**: Tests cover different aspects (timing, ordering, calculations)
3. **Falsifiability**: Tests are designed to fail if assumptions are wrong
4. **Completeness**: Tests cover normal cases, edge cases, and error cases
5. **Independence**: Tests don't depend on each other (can run in any order)

## Wrong Assumptions Proven

The test suite specifically targets and proves wrong these common misconceptions:

1. "All processes complete exactly at arrival time + burst time"
   - **Proven Wrong**: Preemption causes some processes to be delayed

2. "Non-preemptive SJN is always faster than preemptive SRT"
   - **Proven Wrong**: SRT typically has lower average waiting time

3. "Context switch penalty doesn't affect scheduling results"
   - **Proven Wrong**: Penalty delays completion times

4. "SRT and SJN are the same algorithm"
   - **Proven Wrong**: SRT is preemptive, SJN is non-preemptive

5. "Burst time can be zero"
   - **Proven Wrong**: A process with zero burst time doesn't make sense

6. "All processes must arrive at time 0"
   - **Proven Wrong**: Processes can arrive at any time
