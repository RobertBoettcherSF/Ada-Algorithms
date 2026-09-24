# Ada-round-robin

Ada implementation of the Round-robin scheduling algorithm with three variants:
- **Standard Round-Robin**: Fixed time quantum for all processes
- **Weighted Round-Robin (WRR)**: Time quantum scaled by process weight
- **Deficit Round-Robin (DRR)**: Deficit-based scheduling with atomic chunk support

## Project Structure

```
.
├── round_robin.adb          # Main implementation
├── round_robin.ads          # Specification file
├── round_robin.gpr          # GPR project file
├── README.md                # This file
└── tests/                   # Test suite
    ├── round_robin_tests.adb    # Test implementations (package body)
    ├── round_robin_tests.ads    # Test specifications
    └── run_round_robin_tests.adb # Main procedure to run tests
```

## Building and Running

### Prerequisites

- GNAT Ada compiler (part of GCC)
- GPRBuild (optional, for project file support)

#### Install on Ubuntu/Debian:
```bash
sudo apt-get install gnat gprbuild
```

#### Install on Fedora/RHEL:
```bash
sudo dnf install gcc-gnat gprbuild
```

### Running the Main Program

```bash
# Using gnatmake directly
gnatmake -P round_robin.gpr
./round_robin

# Or compile and run manually
gnatmake round_robin.adb
./round_robin
```

### Running the Test Suite

The tests are in `tests/round_robin_tests.adb` (package body) and `tests/run_round_robin_tests.adb` (main procedure).

```bash
# From the repository root:
cd tests
gnatmake run_round_robin_tests.adb
./run_round_robin_tests
```

**All 72 tests pass successfully!**

## Test Suite

The test suite contains **24 test procedures** organized into 6 test suites, with a total of **72 assertions**:

### Test Suite 1: Standard Round Robin (5 test procedures, 13 assertions)
- Empty queue handling
- Single process execution
- Process preemption at quantum boundary
- Multiple processes round-robin order
- Completion order verification

### Test Suite 2: Weighted Round Robin (5 test procedures, 13 assertions)
- Weight allocation correctness
- Higher weight gets more CPU time
- Weight=1 behaves like standard RR
- Zero burst time handling
- Large weight handling

### Test Suite 3: Deficit Round Robin (5 test procedures, 14 assertions)
- Deficit accumulation across rounds
- Atomic chunk constraint enforcement
- Completion when deficit is sufficient
- Fairness with multiple processes
- Deficit preservation across rounds

### Test Suite 4: Edge Cases and Boundary Conditions (5 test procedures, 14 assertions)
- All algorithms with empty input
- Zero quantum edge case
- Very large burst time handling
- Process order preservation
- Mixed arrival times

### Test Suite 5: Assumptions That Can Be Proven False (6 test procedures, 12 assertions)
- RR preempts exactly at quantum boundary
- Weight should never be zero
- Deficit should never be negative
- Atomic chunk should be positive
- Remaining time should never be negative
- Process IDs should be unique

### Test Suite 6: Integration Tests (3 test procedures, 6 assertions)
- Standard RR full execution to completion
- Weighted RR full execution to completion
- Deficit RR full execution to completion

### Test Design Principles

1. **Assumptions about code not doing anything or doing it wrong**: Each test verifies a specific assumption about how the code should behave. For example, we test that processes with burst time equal to the quantum complete rather than being preempted.

2. **Tests that test for different assumptions**: The tests cover different aspects of the algorithms:
   - Correctness of scheduling logic
   - Edge case handling
   - Type safety (Positive types prevent invalid values)
   - Fairness and order preservation
   - Boundary conditions

3. **Can be proven false**: Each test includes assertions that will fail if the assumption is wrong. For example:
   - If a process with burst=quantum is preempted instead of completed, the test fails
   - If deficit becomes negative, the test fails
   - If process order is not preserved, the test fails

## Test Output

When you run the tests, you'll see output like:

```
========================================
  ROUND ROBIN TEST SUITE
========================================

--- Test Suite 1: Standard Round Robin ---
Test 1.1: Standard RR with empty queue
  [PASS] Queue should be empty initially
  [PASS] Current time should remain 0 for empty queue: Expected  0, got  0
  [PASS] Queue should still be empty
Test 1.2: Standard RR with single process
  [PASS] Queue should have 1 process: Expected  1, got  1
  [PASS] Process should be finished: Expected  0, got  0
  ...

--- Test Suite 2: Weighted Round Robin ---
  [PASS] Weight 1 should give quantum of 2: Expected  2, got  2
  [PASS] Weight 2 should give quantum of 4: Expected  4, got  4
  ...

========================================
  TEST SUMMARY
========================================
Total Tests:   72
Passed:       72
Failed:       0
Result:       ALL TESTS PASSED
========================================
```

## Implementation Details

### Process_Info Type

Each process is represented by a `Process_Info` record containing:
- `ID`: Unique process identifier (Process_ID, based on Positive)
- `Arrival_Time`: When the process arrived (currently stored but not used in scheduling)
- `Burst_Time`: Total CPU time required
- `Remaining_Time`: CPU time still needed
- `Weight`: Priority weight for WRR (minimum 1)
- `Deficit`: Accumulated deficit for DRR
- `Atomic_Chunk`: Minimum execution unit for DRR

### Algorithms

#### Standard Round-Robin
- Each process gets a fixed time quantum
- If process doesn't complete within quantum, it's preempted and moved to back of queue
- Continues until all processes complete

#### Weighted Round-Robin
- Each process gets quantum * weight time
- Higher weight processes get more CPU time per round
- Maintains fairness while providing priority

#### Deficit Round-Robin
- Each process accumulates a deficit (quantum per round)
- Can execute up to min(remaining_time, deficit)
- Execution happens in atomic chunks
- Unused deficit is preserved across rounds

## Contributing

To add new tests:

1. Add a new test procedure in `tests/round_robin_tests.adb`
2. Call it from `Run_All_Tests` procedure
3. Follow the existing pattern of using `Test_Assert`, `Test_Assert_Equal_Natural`, etc.

To modify the algorithms:

1. Edit `round_robin.adb`
2. Run the test suite to verify correctness
3. Update tests if behavior changes intentionally

## License

This project is open source. Feel free to use, modify, and distribute.
