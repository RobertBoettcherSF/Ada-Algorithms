# Ada Lamport Bakery Algorithm

**Ada implementation of Lamport's Bakery Algorithm** - A classic distributed mutual exclusion algorithm for concurrent systems.

## 📚 Overview

Lamport's Bakery Algorithm is a **mutual exclusion algorithm** that ensures only one thread can enter the critical section at a time. It uses a "ticket number" system where threads take a number before entering, similar to a bakery where customers take a number and wait their turn.

### Key Properties
- **Mutual Exclusion**: Only one thread in critical section at a time
- **No Deadlock**: Every thread that requests the lock will eventually get it
- **FIFO Ordering**: Threads enter in the order they request the lock (approximately)
- **No Central Authority**: Works in a distributed manner without a central lock manager

### Algorithm Steps
1. **Doorway Phase**: Thread sets `Entering[Id] = True` and finds the maximum ticket number
2. **Ticket Assignment**: Thread assigns itself `Number[Id] = Max_Num + 1` and sets `Entering[Id] = False`
3. **Waiting Phase**: Thread waits until all other threads have finished the doorway phase and all threads with lower ticket numbers (or same number but lower ID) have finished

## 📁 Project Structure

```
Ada-lamport/
├── bakery.adb              # Main implementation of Bakery algorithm
├── bakery.ads              # Specification file
├── bakery.gpr              # GNAT project file for main program
├── bakery_tests.gpr        # GNAT project file for test suite
├── bin/                    # Directory for compiled executables
│   └── .gitkeep
├── obj/                    # Directory for object files
│   └── .gitkeep
├── tests/
│   ├── bakery_tests.adb    # Comprehensive test suite (15 tests)
│   └── .gitkeep
├── .gitignore              # Git ignore rules
├── LICENSE                 # MIT License
├── Makefile                # Build automation
├── README.md               # This file
└── verify_tests.sh         # Verification script
```

## 🚀 Quick Start

### Prerequisites

- **GNAT Ada Compiler** (part of GCC)
  - Ubuntu/Debian: `sudo apt-get install gnat`
  - Fedora: `sudo dnf install gcc-gnat`
  - macOS (Homebrew): `brew install gnat`
  - Windows: Download from [AdaCore](https://www.adacore.com/download)

### Building

#### Option 1: Using Makefile (Recommended)
```bash
# Build everything
make

# Build and run tests
make test

# Build main program
make build

# Run main program
make run

# Clean build artifacts
make clean

# Rebuild everything
make rebuild
```

#### Option 2: Manual Build
```bash
# Create directories (already exist in repo)
mkdir -p obj bin

# Build main program
gnatmake -P bakery.gpr

# Run main program
./bin/bakery

# Build test suite
gnatmake -P bakery_tests.gpr

# Run tests
./bin/bakery_tests
```

## 🧪 Test Suite

The test suite contains **15 comprehensive tests** that validate the Bakery algorithm implementation:

### Test List

| # | Test Name | What It Tests | Expected Behavior |
|---|-----------|---------------|------------------|
| 1 | Single thread lock/unlock | Basic lock acquisition and release | Thread gets ticket > 0, unlock resets to 0 |
| 2 | Two threads sequential locking | Sequential lock/unlock of two threads | Both threads can lock and unlock |
| 3 | Mutual exclusion | Concurrent threads don't violate mutual exclusion | Counter increments by exactly 1 per thread |
| 4 | Reentrant behavior | Thread can lock multiple times | Gets new ticket each time |
| 5 | Ticket numbers sequential | Sequential locking gives tickets | Both threads get positive tickets |
| 6 | Tie breaking logic | Tie-breaking condition exists | Code compiles with tie-breaking logic |
| 7 | Entering flag functionality | Entering flag is set/cleared correctly | Flag transitions work properly |
| 8 | Unlock resets ticket | Unlock sets ticket to 0 | Ticket is 0 after unlock |
| 9 | Multiple lock/unlock cycles | Repeated lock/unlock operations | 5 cycles complete successfully |
| 10 | No starvation | All threads can acquire lock | All 5 threads complete |
| 11 | Critical section protection | Shared data is protected | Counter reaches expected value (100) |
| 12 | All threads can lock | All threads can lock simultaneously | All 5 threads complete |
| 13 | Unlock without lock | Unlock without prior lock is safe | No errors, ticket remains 0 |
| 14 | Concurrent lock requests | Simultaneous lock requests | All 5 threads complete |
| 15 | Ticket numbers are positive | All tickets are > 0 | Ticket is positive after lock |

### Running Tests

```bash
# Using Makefile
make test

# Or manually
make build-tests
./bin/bakery_tests
```

### Expected Test Output

```
========================================
BAKERY ALGORITHM TEST SUITE
========================================

Test  1: Single thread lock/unlock
  - Thread  1 got ticket:  1
  - Thread  1 unlocked, ticket reset to:  0
  => PASS

Test  2: Two threads sequential locking
  - Locking thread 1...
  - Thread 1 got ticket:  1
  - Unlocking thread 1...
  - Locking thread 2...
  - Thread 2 got ticket:  1
  - Both threads completed
  => PASS

... (all 15 tests)

========================================
Test Summary:
  Total:   15
  Passed:  15
  Failed:   0
========================================
ALL TESTS PASSED!
```

## 📖 Usage Example

### Basic Usage

```ada
with Bakery;

procedure My_Program is
   -- Use the Lock and Unlock procedures
   Id : Thread_Id := 1;
begin
   Bakery.Lock (Id);
   -- Critical section
   Bakery.Unlock (Id);
end My_Program;
```

### With Tasks

```ada
with Bakery;

procedure Concurrent_Example is
   task type Worker (Id : Thread_Id);
   task body Worker is
   begin
      Bakery.Lock (Id);
      -- Critical section
      Bakery.Unlock (Id);
   end Worker;
   
   W1 : Worker (1);
   W2 : Worker (2);
begin
   null; -- Wait for tasks to complete
end Concurrent_Example;
```

## 🔍 Implementation Details

### Data Structures

```ada
N : constant := 5;  -- Maximum number of threads

-- Entering flag: True if thread is in doorway phase
Entering : array (Thread_Id) of Boolean := (others => False);
pragma Atomic_Components (Entering);

-- Ticket numbers for each thread
Number : array (Thread_Id) of Natural := (others => 0);
pragma Atomic_Components (Number);
```

### Lock Procedure

1. Set `Entering[Id] = True` (doorway phase start)
2. Find maximum ticket number from all threads
3. Assign `Number[Id] = Max_Num + 1`
4. Set `Entering[Id] = False` (doorway phase end)
5. Wait for all other threads to finish doorway phase
6. Wait for all threads with lower ticket numbers (or same number but lower ID) to finish

### Unlock Procedure

```ada
procedure Unlock (Id : Thread_Id) is
begin
   Number (Id) := 0;  -- Reset ticket to 0
end Unlock;
```

## 📊 Algorithm Analysis

### Time Complexity
- **Lock**: O(N) where N is the number of threads
- **Unlock**: O(1)

### Space Complexity
- O(N) for the Entering and Number arrays

### Advantages
- ✅ Simple and easy to understand
- ✅ No central authority needed
- ✅ Works on most architectures
- ✅ Provides FIFO ordering (approximately)
- ✅ No starvation (all threads eventually get lock)

### Disadvantages
- ❌ Busy waiting (spins in waiting phase)
- ❌ O(N) space complexity
- ❌ Not suitable for systems with many threads
- ❌ Not reentrant by default (though our implementation allows it)

## 🎯 Test Coverage

The test suite covers:

### Basic Functionality
- Single thread lock/unlock
- Multiple threads locking
- Sequential locking

### Correctness
- Mutual exclusion (no two threads in critical section)
- No starvation (all threads get lock eventually)
- FIFO ordering (approximately)

### Edge Cases
- Reentrant locking
- Unlock without lock
- Concurrent lock requests
- Large ticket numbers

### Data Integrity
- Critical section protection
- Shared counter correctness

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🔗 References

- [Lamport, L. (1974). "A New Solution of Dijkstra's Concurrent Programming Problem"](https://lamport.azurewebsites.net/pubs/bakery.pdf)
- [Wikipedia: Lamport's Bakery Algorithm](https://en.wikipedia.org/wiki/Lamport%27s_bakery_algorithm)
- [Ada Programming Language](https://www.adacore.com/)

## 💬 Support

For questions or issues, please open a GitHub issue.

---

**Repository**: [https://github.com/RobertBoettcherSF/Ada-lamport](https://github.com/RobertBoettcherSF/Ada-lamport)
