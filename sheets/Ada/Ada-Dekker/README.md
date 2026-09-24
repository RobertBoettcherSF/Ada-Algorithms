# Ada-Dekker: Dekker's Algorithm Implementation in Ada

This project implements **Dekker's algorithm** and its variants in Ada, demonstrating classical solutions to the mutual exclusion problem in concurrent programming.

## What is Dekker's Algorithm?

Dekker's algorithm is a **software-based solution** to the mutual exclusion problem - ensuring that only one process/thread can access a shared resource (critical section) at a time. It was one of the first correct algorithms for mutual exclusion, proposed by Dutch mathematician Th. J. Dekker.

## Project Structure

### Main Implementation (`dekker.adb`)

Contains three algorithm variants:

1. **Naive Turn Taking** (`Naive_Turn_Taking`)
   - Simple strict alternation using a `Turn` variable
   - **Limitation:** Fails if one process halts or does more iterations than the other
   - Demonstrates the basic concept but is not robust

2. **Starvation Susceptible** (`Starvation_Susceptible`)
   - Implements the entry protocol with flags (`Wants_To_Enter`)
   - **Limitation:** Missing the turn check in the back-off, can lead to starvation
   - One process might dominate access to the critical section

3. **Full Dekker** (`Full_Dekker`)
   - The **complete and correct** algorithm
   - Combines flags with turn-based back-off
   - Guarantees: **Mutual Exclusion**, **Progress**, and **Bounded Waiting**
   - No starvation: every process gets access within a bounded time

### Test Suite (`tests/dekker_tests.adb`)

Comprehensive test suite with **10 test procedures** organized into 4 groups, totaling **33 assertions**:

- **Group 1 (Tests 1.1-1.4): Basic State Verification**
  - 1.1: Initial state verification (6 assertions)
  - 1.2: Turn alternation (2 assertions)
  - 1.3: Flag reset (4 assertions)
  - 1.4: Counter monotonic increase (3 assertions)

- **Group 2 (Tests 2.1-2.4): Full Dekker Algorithm**
  - 2.1: Mutual exclusion (4 assertions)
  - 2.2: Progress (3 assertions)
  - 2.3: No starvation (3 assertions)
  - 2.4: No deadlock (2 assertions)

- **Group 3 (Test 3.1): Naive Turn Taking Algorithm**
  - 3.1: Equal iterations (3 assertions)

- **Group 4 (Test 4.1): Starvation Susceptible Algorithm**
  - 4.1: Fairness (3 assertions)

## What the Tests Verify

The test suite verifies three fundamental properties of mutual exclusion algorithms:

1. **Mutual Exclusion**: Only one process can be in the critical section at any time
2. **Progress**: If no process is in the critical section, a waiting process can enter
3. **Bounded Waiting**: No process waits forever to enter the critical section

Additionally, the tests verify:
- Correct initialization of shared state
- Proper alternation of the turn variable
- Accurate counter increments
- No deadlock situations
- Fair access between processes

## Why This Matters

Dekker's algorithm is historically significant because it was:
- One of the first **correct** software solutions to mutual exclusion
- Proved that mutual exclusion could be achieved **without hardware support**
- A foundation for understanding more complex synchronization algorithms

While modern systems use hardware-supported primitives (mutexes, semaphores), understanding Dekker's algorithm provides insight into:
- The challenges of concurrent programming
- The importance of careful algorithm design
- How to reason about correctness in concurrent systems

## Usage

### Prerequisites

- **GNAT** (GNU Ada compiler)
  - Ubuntu/Debian: `sudo apt install gnat`
  - macOS: `brew install gnat`
  - Windows: Download from [AdaCore](https://www.adacore.com/download)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-Dekker.git
cd Ada-Dekker

# Build everything
make

# Run the demonstration
make run

# Run the test suite
make test

# Clean build files
make clean
```

### Manual Commands

```bash
# Build the main demonstration
gnatmake -P dekker.gpr
./obj/dekker

# Build and run tests
cd tests
gnatmake -P tests.gpr
cd ..
./obj/dekker_tests
```

### Expected Output

**Demonstration (`make run`):**
```
=== Dekker's Algorithm Demonstration ===

--- Testing Variant: NAIVE_TURN_TAKING ---
Process P0 entering CS (Naive).
Process P1 entering CS (Naive).
... (10 total entries)
--- Final Counter for NAIVE_TURN_TAKING:  10 (Expected: 10) ---

--- Testing Variant: STARVATION_SUSCEPTIBLE ---
... (10 total entries)
--- Final Counter for STARVATION_SUSCEPTIBLE:  10 (Expected: 10) ---

--- Testing Variant: FULL_DEKKER ---
... (10 total entries)
--- Final Counter for FULL_DEKKER:  10 (Expected: 10) ---

=== Demonstration Finished ===
```

**Test Suite (`make test`):**
```
=== Dekker's Algorithm Test Suite ===
Running with Test_Iterations =  3
Running tests in 4 groups:
  Group 1 (Tests 1.1-1.4): Basic State Verification
  Group 2 (Tests 2.1-2.4): Full Dekker Algorithm
  Group 3 (Tests 3.1): Naive Turn Taking Algorithm
  Group 4 (Tests 4.1): Starvation Susceptible Algorithm

TEST 1.1: Initial State Verification
  [PASS] P0 flag initially False
  ...

=== Test Summary ===
Total Assertions:  33
Passed:  33
Failed:  0
All tests PASSED!
=== Test Suite Finished ===
```

## Algorithm Details

### Naive Turn Taking

```ada
while Turn /= ID loop
   delay 0.0; -- Yield
end loop;
-- Critical Section
Turn := Other;
```

**Problem:** If P0 does 5 iterations and P1 does 3, P0 will be stuck waiting for Turn=P0 after P1 exits.

### Starvation Susceptible

```ada
Wants_To_Enter(ID) := True;
while Wants_To_Enter(Other) loop
   Wants_To_Enter(ID) := False;
   while Turn /= ID loop
      delay 0.0;
   end loop;
   Wants_To_Enter(ID) := True;
end loop;
-- Critical Section
Turn := Other;
Wants_To_Enter(ID) := False;
```

**Problem:** Without checking Turn in the outer loop, a process might be starved.

### Full Dekker (Correct)

```ada
Wants_To_Enter(ID) := True;
while Wants_To_Enter(Other) loop
   if Turn /= ID then
      Wants_To_Enter(ID) := False;
      while Turn /= ID loop
         delay 0.0;
      end loop;
      Wants_To_Enter(ID) := True;
   end if;
end loop;
-- Critical Section
Turn := Other;
Wants_To_Enter(ID) := False;
```

**Guarantees:** Mutual exclusion, progress, and bounded waiting.

## Technical Notes

- **Atomic Variables**: Uses `pragma Atomic` and `pragma Atomic_Components` to ensure safe concurrent access
- **Delay**: Uses `delay 0.0;` as a yield mechanism to prevent CPU hogging
- **Task Synchronization**: Ada tasks start immediately and run concurrently
- **Test Reliability**: Tests accept partial completion (≥ 2 iterations) to account for task abort on procedure exit

## License

This project is open source and available for educational use.

## References

- [Dekker's Algorithm on Wikipedia](https://en.wikipedia.org/wiki/Dekker%27s_algorithm)
- Ada Programming Language documentation
- Concurrent Programming principles
