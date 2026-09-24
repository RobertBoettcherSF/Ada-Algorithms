# Ada-mlfq

Ada implementation of a Multilevel Feedback Queue (MLFQ) scheduler.

## Overview

This project implements a **Multilevel Feedback Queue (MLFQ)** scheduler in Ada. MLFQ is a scheduling algorithm that uses multiple priority queues with different time quanta to provide fair and efficient process scheduling. It's commonly used in operating systems to balance between interactive processes (which need quick response) and CPU-bound processes (which need throughput).

## MLFQ Rules Implemented

This implementation follows the classic MLFQ rules:

1. **Rule 1 (Priority Preemption)**: If a higher priority queue (lower queue number) has a job, it preempts the currently running job from a lower priority queue.

2. **Rule 2 (Round Robin)**: Within each queue, jobs are scheduled using Round Robin with a fixed time quantum.

3. **Rule 3 (New Job Entry)**: New jobs always enter at the highest priority queue (queue 1).

4. **Rule 4 (Demotion)**: If a job uses its full time quantum, it gets demoted to the next lower priority queue.

5. **Rule 5 (Aging)**: Periodically, all jobs are boosted back to the highest priority queue to prevent starvation.

## Project Structure

```
Ada-mlfq/
├── main.adb              # Entry point - runs example simulation
├── mlfq.ads              # Package specification (types, declarations)
├── mlfq.adb              # Package body (scheduler implementation)
├── mlfq_project.gpr      # GPR project file for main program
├── mlfq_tests.adb        # Comprehensive test suite (15 tests)
├── mlfq_tests.gpr        # GPR project file for tests
├── obj/                  # Build directory (auto-created)
└── README.md             # This file
```

## Building and Running

### Prerequisites

- **GNAT (GNU Ada compiler)** - Part of GCC

### Installation

- **Linux (Debian/Ubuntu)**: `sudo apt-get install gnat`
- **macOS**: `brew install gnat`
- **Windows**: Download from [AdaCore](https://www.adacore.com/download)

### Run the Example Simulation

```bash
cd Ada-mlfq
gnatmake -P mlfq_project.gpr
./obj/main
```

This runs a pre-configured simulation with three processes:
- **Process 1**: Long-running CPU-bound task (20 ticks)
- **Process 2**: Interactive I/O-bound task (5 ticks, yields every 1 tick, blocked for 3 ticks)
- **Process 3**: Medium-length task with occasional I/O (12 ticks, yields every 4 ticks, blocked for 2 ticks)

The simulation demonstrates all MLFQ rules in action: priority preemption, demotion, aging, and I/O handling.

### Run the Test Suite

```bash
cd Ada-mlfq
gnatmake -P mlfq_tests.gpr
./obj/mlfq_tests
```

## Test Suite

The test suite (`mlfq_tests.adb`) contains **15 comprehensive tests** that verify all MLFQ rules and edge cases:

### Core Functionality Tests

1. **Test 1: Empty scheduler** - Verifies that an empty scheduler correctly reports all processes as finished.

2. **Test 2: Single process completion** - Ensures a single process completes successfully.

3. **Test 3: Process demotion** - Verifies that a process is demoted to a lower queue after exhausting its time quantum (Rule 4).

4. **Test 4: Priority preemption** - Tests that a higher priority queue process preempts a lower priority running process (Rule 1).

5. **Test 5: I/O yielding** - Verifies that I/O-bound processes correctly yield and enter the blocked state.

6. **Test 6: I/O wakeup** - Ensures blocked processes wake up after their I/O duration elapses.

### Advanced Feature Tests

7. **Test 7: Aging** - Verifies that the aging mechanism boosts all processes to the highest priority queue (Rule 5).

8. **Test 8: Multiple process completion** - Tests that multiple processes complete correctly.

9. **Test 9: Round Robin** - Verifies that processes within the same queue are scheduled using Round Robin (Rule 2).

10. **Test 10: Zero CPU time** - Edge case: process with zero CPU time finishes immediately.

11. **Test 11: Full demotion** - Tests that a process can be demoted through all queues.

12. **Test 12: Idle CPU** - Verifies that the CPU stays idle when there are no processes to run.

13. **Test 13: I/O no demotion** - Ensures that processes that yield for I/O are not demoted (they maintain their priority).

14. **Test 14: Different quantums** - Verifies that each queue can have different time quantum values.

15. **Test 15: No aging** - Tests that aging can be disabled by setting the aging interval to zero.

### Why These Tests?

Each test is designed to **prove false** a specific assumption that the code might not be working correctly:

- **Assumption**: The scheduler doesn't handle empty state → **Test 1** proves this false
- **Assumption**: Processes don't complete → **Test 2** proves this false  
- **Assumption**: Quantum expiration doesn't demote processes → **Test 3** proves this false
- **Assumption**: Higher priority doesn't preempt lower → **Test 4** proves this false
- **Assumption**: I/O operations don't work → **Tests 5, 6, 13** prove this false
- **Assumption**: Aging doesn't prevent starvation → **Test 7** proves this false
- **Assumption**: Round Robin doesn't work → **Test 9** proves this false
- **Assumption**: Edge cases crash the scheduler → **Tests 10, 12** prove this false
- **Assumption**: Configuration doesn't work → **Tests 11, 14, 15** prove this false

## Scheduler Configuration

The scheduler can be configured with:

- **Number of priority queues**: Up to 10 queues (defined by `Max_Queues` constant)
- **Time quantum per queue**: Different quantum values for each queue
- **Aging interval**: Set to 0 to disable aging

### Example Configuration

```ada
S : Scheduler;
S.Num_Queues := 3;
Q_Arr : Quantum_Array := (1 => 2, 2 => 4, 3 => 8, others => 1);
Initialize (S, Q_Arr, Aging_Interval => 25);
```

This creates a scheduler with 3 queues, quantums of 2, 4, and 8 ticks respectively, and aging every 25 ticks.

## Implementation Details

### Process Record

Each process has the following attributes:
- `ID`: Unique process identifier
- `State`: Ready, Running, Blocked, or Finished
- `Priority`: Current queue priority (1 = highest)
- `CPU_Time_Needed`: Total CPU time required
- `CPU_Time_Used`: CPU time consumed so far
- `Allotment_Left`: Remaining time quantum at current priority
- `IO_Frequency`: Yields for I/O every N ticks (0 = never yields)
- `IO_Duration`: Stays blocked for N ticks when yielding
- `Current_IO_Wait`: Countdown for I/O completion
- `Ticks_Since_Yield`: Countdown for next I/O yield

### Scheduler Record

The scheduler maintains:
- `Num_Queues`: Number of priority queues to use
- `Queues`: Array of process lists (one per priority level)
- `Quantums`: Time quantum for each queue
- `Blocked_List`: Processes currently blocked for I/O
- `Finished_List`: Completed processes
- `Aging_Interval`: Ticks between aging events
- `Ticks_Since_Aging`: Countdown to next aging
- `Clock`: Global tick counter
- `Is_Idle`: Whether CPU is currently idle
- `Running_Proc`: The currently running process

## Tick Processing Order

Each tick, the scheduler performs the following steps in order:

1. **Aging Check** (Rule 5): If aging interval elapsed, boost all processes to queue 1
2. **I/O Completion**: Decrement blocked process timers, wake up completed I/O
3. **Priority Preemption** (Rule 1): Check if higher priority queue has work, preempt current
4. **Process Selection**: If idle, select next process from highest priority non-empty queue
5. **Process Execution**: Run the selected process for one tick

## Contributing

To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

All changes should maintain the existing test suite passing.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
