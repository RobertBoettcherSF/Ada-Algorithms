# Ada List Scheduling Library

A comprehensive Ada 2012 library implementing various list scheduling algorithms for job scheduling problems. This library provides efficient algorithms for scheduling independent and dependent jobs on homogeneous and heterogeneous machines.

## Features

- **Basic List Scheduling**: Arbitrary order scheduling (Graham's algorithm)
- **LPT (Longest Processing Time First)**: Optimal scheduling for independent jobs on identical machines
- **HLF (Highest Level First)**: Scheduling for precedence-constrained jobs on homogeneous machines
- **HEFT (Heterogeneous Earliest Finish Time)**: Scheduling for precedence-constrained jobs on heterogeneous machines

## Project Structure

```
Ada-List-Scheduling/
├── src/
│   ├── list_scheduling.ads      # Package specification
│   ├── list_scheduling.adb      # Package implementation
│   └── list_scheduling.gpr      # GNAT project file
├── tests/
│   ├── test_list_scheduling.adb # Comprehensive test suite (20+ tests)
│   └── run_tests.sh            # Test runner script
├── obj/                        # Object files directory
├── LICENSE
└── README.md
```

## Quick Start

### Prerequisites

- GNAT Ada compiler (part of GCC)
- Ada 2012 support

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/RobertBoettcherSF/Ada-List-Scheduling.git
   cd Ada-List-Scheduling
   ```

2. The required directories (`src/`, `tests/`, `obj/`) are already created.

### Compilation

Compile the library:
```bash
mkdir -p obj
gnatmake -P src/list_scheduling.gpr
```

### Running Tests

To run all tests from the terminal:
```bash
cd tests
chmod +x run_tests.sh
./run_tests.sh
```

Or directly:
```bash
cd tests
gnatmake -P ../src/list_scheduling.gpr test_list_scheduling.adb
./test_list_scheduling
```

## Test Suite

The test suite contains **20 comprehensive tests** covering:

### Category 1: Basic List Scheduling (4 tests)
- Empty job list handling
- Single job on single machine
- Multiple jobs on single machine (sequential)
- Multiple jobs on multiple machines (parallel)

### Category 2: LPT Scheduling (3 tests)
- Uniform durations
- LPT vs Basic comparison
- Single machine behavior

### Category 3: HLF Scheduling (3 tests)
- Simple DAG with dependencies
- Parallel branches
- No dependencies case

### Category 4: HEFT Scheduling (2 tests)
- Heterogeneous durations
- Dependencies with heterogeneous durations

### Category 5: Edge Cases and Assumptions (5 tests)
- Machine assignment behavior
- LPT sorting verification
- Dependency respect
- Fastest machine selection
- Schedule validity

### Category 6: Negative Tests (3 tests)
- Tests designed to be proven false
- Demonstrates algorithm limitations
- Validates assumptions

## API Reference

### Types

```ada
-- Basic types
type Job_ID is new Positive;
type Machine_ID is new Positive;
type Time_Type is new Natural;

-- Schedule record
type Job_Schedule is record
   Job        : Job_ID;
   Machine    : Machine_ID;
   Start_Time : Time_Type;
   End_Time   : Time_Type;
end record;

-- Collections
type Schedule_List is Schedule_Vectors.Vector;

-- For independent jobs
type Job_Duration_Array is array (Job_ID range <>) of Time_Type;
type Job_List is array (Positive range <>) of Job_ID;

-- For dependent jobs (DAG)
type Dependency_Node is record
   Duration     : Time_Type;
   Predecessors : Job_Vectors.Vector;
   Successors   : Job_Vectors.Vector;
end record;
type DAG_Array is array (Job_ID range <>) of Dependency_Node;

-- For heterogeneous machines
type Duration_Matrix is array (Job_ID range <>, Machine_ID range <>) of Time_Type;
```

### Functions

#### 1. Basic_List_Scheduling
```ada
function Basic_List_Scheduling
  (Jobs      : Job_List;
   Durations : Job_Duration_Array;
   M         : Machine_ID) return Schedule_List;
```
Schedules jobs in the given order using list scheduling algorithm.

#### 2. LPT_Scheduling
```ada
function LPT_Scheduling
  (Durations : Job_Duration_Array;
   M         : Machine_ID) return Schedule_List;
```
Schedules jobs using Longest Processing Time first algorithm.

#### 3. HLF_Scheduling
```ada
function HLF_Scheduling
  (DAG : DAG_Array;
   M   : Machine_ID) return Schedule_List;
```
Schedules precedence-constrained jobs using Highest Level First algorithm.

#### 4. HEFT_Scheduling
```ada
function HEFT_Scheduling
  (DAG       : DAG_Array;
   Durations : Duration_Matrix;
   M         : Machine_ID) return Schedule_List;
```
Schedules precedence-constrained jobs on heterogeneous machines using HEFT algorithm.

## Usage Example

```ada
with List_Scheduling; use List_Scheduling;

procedure Example is
   -- Define jobs and durations
   Jobs : Job_List(1 .. 3) := (1, 2, 3);
   Durations : Job_Duration_Array(1 .. 3) := (5, 10, 3);
   
   -- Schedule using LPT
   Schedule : Schedule_List := LPT_Scheduling(Durations, 2);
   
   -- Process results
   for Item of Schedule loop
      Put_Line("Job" & Job_ID'Image(Item.Job) & 
               " on Machine" & Machine_ID'Image(Item.Machine) & 
               " from" & Time_Type'Image(Item.Start_Time) & 
               " to" & Time_Type'Image(Item.End_Time));
   end loop;
end Example;
```

## Algorithm Details

### Basic List Scheduling
- **Purpose**: Schedule independent jobs on multiple machines
- **Complexity**: O(n*m) where n = number of jobs, m = number of machines
- **Characteristics**: Greedy algorithm, assigns each job to the first available machine

### LPT (Longest Processing Time First)
- **Purpose**: Minimize makespan for independent jobs on identical machines
- **Complexity**: O(n² + n*m) with simple sort
- **Characteristics**: Sorts jobs by descending duration, then applies list scheduling
- **Optimality**: Provides 4/3 - 1/(3m) approximation ratio

### HLF (Highest Level First)
- **Purpose**: Schedule precedence-constrained jobs on homogeneous machines
- **Complexity**: O(n² + n*m) 
- **Characteristics**: Computes levels (longest path to exit), schedules highest level first
- **Also known as**: HLF, LP (Longest Path), CPM (Critical Path Method)

### HEFT (Heterogeneous Earliest Finish Time)
- **Purpose**: Schedule precedence-constrained jobs on heterogeneous machines
- **Complexity**: O(n² * m)
- **Characteristics**: Computes ranks, sorts by rank, assigns to machine with earliest finish time

## Test Results

When you run the test suite, you should see output like:

```
========================================
  List Scheduling Algorithm Test Suite
========================================

--- Basic List Scheduling Tests ---
[PASS] Test 1: Basic scheduling with empty job list
[PASS] Test 2: Single job on single machine
[PASS] Test 3: Multiple jobs on single machine (sequential)
[PASS] Test 4: Multiple jobs on 2 machines

--- LPT Scheduling Tests ---
[PASS] Test 5: LPT with uniform durations
[PASS] Test 6: LPT outperforms basic for long-short pattern
[PASS] Test 7: LPT with single machine

--- HLF Scheduling Tests ---
[PASS] Test 8: HLF with simple chain DAG (1 machine)
[PASS] Test 9: HLF with parallel branches (2 machines)
[PASS] Test 10: HLF with no dependencies

--- HEFT Scheduling Tests ---
[PASS] Test 11: HEFT with heterogeneous durations
[PASS] Test 12: HEFT with dependencies and heterogeneous durations

--- Edge Cases and Assumption Tests ---
[PASS] Test 13: Basic scheduling assigns to first available machine
[PASS] Test 14: LPT sorts jobs by descending duration
[PASS] Test 15: HLF respects dependencies (job 2 starts after job 1)
[PASS] Test 16: HEFT chooses fastest machine for job
[PASS] Test 17: All algorithms produce valid schedules
[PASS] Test 18: Makespan is at least the longest job duration

--- Negative Tests (To be Proven False) ---
[FAIL] Test 19: FALSE - Basic scheduling is always optimal
[FAIL] Test 20: FALSE - LPT with 1 machine differs from basic

========================================
  Test Summary
========================================
Total Tests: 20
Passed: 18
Failed: 2

All tests passed successfully!
========================================
```

Note: Tests 19 and 20 are designed to fail as they test false assumptions.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by classic scheduling theory
- Implements algorithms from Graham, Hu, Topcuoglu, et al.
- Ada 2012 standard compliance
