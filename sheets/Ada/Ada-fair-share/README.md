# Ada Fair-Share Scheduler

A comprehensive implementation of **Fair-Share Scheduling algorithms** in Ada, demonstrating three different approaches to proportional CPU resource allocation among users and processes.

## Overview

This project implements three classic fair-share scheduling algorithms that ensure processes receive CPU time proportional to their allocated shares:

1. **Traditional Unix FSS (Fair Share Scheduler)**
   - Adjusts process priorities based on historical CPU usage
   - Uses priority decay to prevent starvation
   - Priority = Base_Priority + (CPU_Usage / 2) + (User_CPU_Usage / 2)

2. **Completely Fair Scheduler (CFS)**
   - Inspired by the Linux CFS algorithm
   - Uses Virtual Runtime to track fair CPU time allocation
   - Always selects the process with the lowest Virtual Runtime
   - Virtual Runtime increases inversely proportional to share weight

3. **Lottery Scheduling**
   - Probabilistic approach using random selection
   - Processes receive tickets proportional to their share
   - Random lottery draw determines which process runs next
   - Mathematically proven to provide proportional fairness over time

## Project Structure

```
.
├── fair_share_scheduler.ads    # Package specification (types, interfaces)
├── fair_share_scheduler.adb    # Package body (algorithm implementations)
├── main.adb                    # Demo program
├── tests.adb                   # Comprehensive test suite (15 tests)
├── fair_share.gpr              # GNAT project file for demo
├── tests.gpr                   # GNAT project file for tests
├── Makefile                    # Build automation
└── README.md                   # This file
```

## Quick Start

### Prerequisites

- **GNAT Ada Compiler** (part of GCC)
- **gprbuild** (GNAT Project Manager)

**On Ubuntu/Debian:**
```bash
sudo apt-get install gnat gprbuild
```

**On Fedora/RHEL:**
```bash
sudo dnf install gcc-gnat gprbuild
```

**On macOS (using Homebrew):**
```bash
brew install gnat
```

### Building and Running

#### Run the Demo
```bash
make        # Build and run demo
```

Or step by step:
```bash
make clean   # Clean previous builds
make build   # Compile everything
make run     # Run the demo
```

#### Run the Tests
```bash
make test    # Compile and run all 15 tests
```

Or manually:
```bash
make clean
make build
./tests      # Run tests directly
```

### Available Make Targets

| Command | Description |
|---------|-------------|
| `make` | Build and run demo |
| `make build` | Build both demo and tests |
| `make run` | Run the demo program |
| `make test` | Compile and run all tests |
| `make clean` | Remove all build artifacts |

## Demo Program

The `main.adb` demo demonstrates the scheduler with:
- 3 users with shares allocated as 2:1:1
- 4 processes distributed across the users
- 10 time slices showing which process is selected

Output example:
```
Fair-Share Scheduler Demo

Added 4 processes across 3 users with shares 2:1:1

Time slice 1: Running process 1
Time slice 2: Running process 3
Time slice 3: Running process 4
Time slice 4: Running process 2
...
Demo complete!
```

## Test Suite

The comprehensive test suite (`tests.adb`) contains **15 tests** organized into 5 categories:

### 1. Basic Functionality Tests (Tests 1-6)

These verify core scheduler operations:

| Test | Description | What it verifies |
|------|-------------|------------------|
| 1 | Scheduler initialization | Current process is null after init |
| 2 | Adding users | Users can be added without error |
| 3 | Adding processes | Processes can be added without error |
| 4 | Select with no processes | Returns Null_Process when empty |
| 5 | Select with processes | Returns valid Process_ID |
| 6 | Remove process | Process removal works correctly |

**Assumptions tested:**
- Scheduler starts in clean state
- Users and processes can be registered
- Selection returns valid or null appropriately
- Removal works as expected

### 2. Traditional Unix FSS Tests (Tests 7-8)

These verify the priority-based algorithm:

| Test | Description | What it verifies |
|------|-------------|------------------|
| 7 | CPU usage increases | Tick increases process CPU_Usage |
| 8 | Decay reduces usage | Decay_Usage halves CPU_Usage |

**Assumptions tested:**
- CPU usage tracking works correctly
- Priority decay prevents starvation by reducing historical weight

### 3. Completely Fair Scheduler Tests (Tests 9-10, 13)

These verify the virtual runtime algorithm:

| Test | Description | What it verifies |
|------|-------------|------------------|
| 9 | Virtual runtime increases | Tick increases Virtual_Runtime |
| 10 | Selects lowest VR | Process with lowest VR is selected |
| 13 | Fair distribution | Equal shares get equal CPU time |

**Assumptions tested:**
- Virtual runtime accumulates correctly
- CFS always picks the most "starved" process
- Equal shares result in equal distribution

### 4. Lottery Scheduling Tests (Tests 11-12)

These verify the probabilistic algorithm:

| Test | Description | What it verifies |
|------|-------------|------------------|
| 11 | All selected | All processes get selected over time |
| 12 | Proportional selection | 3:1 share ratio results in ~3:1 selection |

**Assumptions tested:**
- Random selection covers all processes
- Selection probability is proportional to shares
- Lottery provides fairness over time

### 5. Edge Case Tests (Tests 14-15)

These verify boundary conditions:

| Test | Description | What it verifies |
|------|-------------|------------------|
| 14 | Max processes limit | Handles adding more than Max_Processes |
| 15 | Max users limit | Handles adding more than Max_Users |

**Assumptions tested:**
- Array bounds are handled gracefully
- Scheduler doesn't crash with overflow

## Test Output

```
Running Fair-Share Scheduler Tests...

Test 1: Scheduler initialization
  PASS: Current process should be null after init
Test 2: Adding users
  PASS: Should be able to add users without error
...
Test 15: Maximum users limit
  PASS: Should handle adding more than Max_Users gracefully

========================================
Test Summary:
  Total:   15
  Passed:  15
  Failed:  0
========================================
ALL TESTS PASSED!
```

## How Each Algorithm Works

### Traditional Unix FSS

**Concept:** Priority-based scheduling with usage decay

```
Dynamic_Priority = Base_Priority + (CPU_Usage / 2) + (User_CPU_Usage / 2)
```

- Lower priority number = higher priority
- Processes that have used more CPU get lower priority
- Periodic decay halves usage counts to prevent starvation
- Simple and effective for interactive systems

### Completely Fair Scheduler (CFS)

**Concept:** Virtual runtime tracking for perfect fairness

```
Virtual_Runtime += Time_Slice / (User_Shares / Active_Processes)
```

- Each process has a Virtual Runtime counter
- Process with lowest VR runs next
- VR increases slower for processes with higher share weights
- Guarantees fair CPU distribution over time

### Lottery Scheduling

**Concept:** Random selection with weighted probability

```
Process_Tickets = (User_Shares / Total_Shares) * Total_System_Tickets / Active_Processes
```

- Each process gets tickets proportional to its share
- Random number between 0 and Total_Tickets selects winner
- Mathematically proven to provide proportional fairness
- Simple implementation, works well in practice

## API Reference

### Types

```ada
-- Algorithm variants
type Algorithm_Type is (
  Traditional_Unix_FSS,
  Completely_Fair_Scheduler_CFS,
  Lottery_Scheduling
);

-- Process and User identifiers
type Process_ID is new Natural;
type User_ID is new Natural;

-- Null constants
Null_Process : constant Process_ID := 0;
Null_User : constant User_ID := 0;

-- Maximum limits
Max_Processes : constant := 1024;
Max_Users : constant := 256;

-- Main scheduler type
type Scheduler (Algorithm : Algorithm_Type) is tagged limited record
  Processes : Process_Array;
  Users : User_Array;
  Current_Process : Process_ID;
  RNG : Ada.Numerics.Float_Random.Generator;
end record;
```

### Procedures

```ada
-- Initialize the scheduler
procedure Initialize (Self : in out Scheduler);

-- Add a user with CPU shares
procedure Add_User (Self : in out Scheduler; ID : User_ID; Shares : Float);

-- Add a process for a user
procedure Add_Process (Self : in out Scheduler;
                       ID : Process_ID;
                       Owner : User_ID;
                       Base_Priority : Float := 10.0;
                       Tickets : Natural := 0);

-- Remove a process
procedure Remove_Process (Self : in out Scheduler; ID : Process_ID);

-- Select next process to run (returns Process_ID)
function Select_Next_Process (Self : in out Scheduler) return Process_ID;

-- Simulate a time slice
procedure Tick (Self : in out Scheduler; Time_Slice : Float);

-- Decay CPU usage (for Traditional FSS)
procedure Decay_Usage (Self : in out Scheduler);
```

## Usage Example

```ada
with Fair_Share_Scheduler;

procedure Example is
   use Fair_Share_Scheduler;
   Sched : Scheduler(Lottery_Scheduling);
begin
   Initialize(Sched);
   
   -- Add users with different shares
   Add_User(Sched, User_ID(1), 2.0);  -- User 1 gets 2 shares
   Add_User(Sched, User_ID(2), 1.0);  -- User 2 gets 1 share
   
   -- Add processes
   Add_Process(Sched, Process_ID(1), User_ID(1));
   Add_Process(Sched, Process_ID(2), User_ID(2));
   
   -- Run scheduler
   for I in 1..100 loop
      declare
         Next : Process_ID := Select_Next_Process(Sched);
      begin
         -- Run the selected process
         Tick(Sched, 1.0);
      end;
   end loop;
end Example;
```

## Implementation Notes

### Why Tagged Limited Type?

The `Scheduler` type is declared as `tagged limited record` because:
- **Tagged:** Allows for future extension (inheritance)
- **Limited:** Required because it contains a limited component (`Ada.Numerics.Float_Random.Generator`)

### Algorithm Selection

The scheduler is generic over the algorithm type:
```ada
type Scheduler (Algorithm : Algorithm_Type) is tagged limited record
```

This means you create a scheduler with a specific algorithm:
```ada
Sched_FSS : Scheduler(Traditional_Unix_FSS);
Sched_CFS : Scheduler(Completely_Fair_Scheduler_CFS);
Sched_Lottery : Scheduler(Lottery_Scheduling);
```

### Performance Considerations

- **Traditional FSS:** O(n) for selection, O(n) for decay
- **CFS:** O(n) for selection, O(1) for tick
- **Lottery:** O(n) for selection, O(1) for tick

All algorithms are linear in the number of processes, which is acceptable for the typical use case (Max_Processes = 1024).

## Testing Philosophy

Each test is designed to:

1. **State a clear assumption** about how the code should behave
2. **Test that assumption** with specific, controlled inputs
3. **Be provably false** - if the implementation is wrong, the test will fail

The tests cover:
- **Happy path:** Normal operation
- **Edge cases:** Boundary conditions
- **Algorithm-specific:** Behavior unique to each algorithm
- **Invariants:** Properties that should always hold

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is open source. See the LICENSE file for details.

---

**Maintained by:** Robert Boettcher

**Last Updated:** July 2026
