# Ada-earliest-deadline

Ada implementation of the Earliest Deadline First (EDF) scheduling algorithm with support for:
- Standard Preemptive EDF
- Standard Non-Preemptive EDF
- EDF with Virtual Deadlines (EDF-VD) for mixed criticality systems

## Features

- **Multiple Scheduling Variants**: Standard Preemptive, Standard Non-Preemptive, and EDF-VD
- **Task Types**: Periodic and Aperiodic tasks
- **Criticality Levels**: Low and High criticality support
- **Schedulability Analysis**: Utilization-based schedulability test for periodic tasks
- **Deadline Miss Detection**: Runtime detection and reporting of missed deadlines
- **Comprehensive Test Suite**: 17 automated tests covering various scenarios

## Project Structure

```
.
├── edf_scheduling.ads          # Package specification
├── edf_scheduling.adb          # Package implementation
├── edf_scheduling.gpr          # GPR project file
├── edf_demo.gpr                    # GPR project file for demo program
├── main.adb                    # Demonstration program
├── Makefile                    # Build automation
├── tests/
│   ├── edf_tests.adb           # Comprehensive test suite (17 tests)
│   └── test_runner.gpr         # GPR project file for tests
├── README.md                   # This file
└── LICENSE
```

## Quick Start

### Prerequisites

Install the GNAT Ada compiler:

- **Ubuntu/Debian**: `sudo apt install gnat gprbuild`
- **macOS (Homebrew)**: `brew install gnat`
- **Windows**: Download from [libre.adacore.com](https://libre.adacore.com/)

### Building and Running

#### Option 1: Using Make (Recommended)

```bash
# Build and run all tests
make test

# Build the main demonstration
make build

# Run the demonstration
make run

# Clean build artifacts
make clean

# Show help
make help
```

#### Option 2: Manual Compilation

```bash
# Create required directories (they exist in the repo but may need recreation after clean)
mkdir -p obj bin

# Build the main demonstration program
gprbuild -P edf_demo.gpr
./bin/main

# Build and run tests
gprbuild -P tests/test_runner.gpr
./bin/edf_tests
```

## Test Suite

The test suite contains **17 comprehensive tests** that validate the EDF scheduling algorithm:

### Schedulability Tests (7 tests)
1. **Test_Empty_System**: Empty system is schedulable
2. **Test_Single_Periodic_Schedulable**: Single periodic task with utilization < 1
3. **Test_Single_Periodic_Boundary**: Single periodic task with utilization = 1
4. **Test_Single_Periodic_Overloaded**: Single periodic task with utilization > 1
5. **Test_Multiple_Periodic_Schedulable**: Multiple tasks with combined utilization <= 1
6. **Test_Multiple_Periodic_Overloaded**: Multiple tasks with combined utilization > 1
7. **Test_Aperiodic_Tasks_Ignored_In_Schedulability**: Aperiodic tasks don't affect utilization

### Simulation Tests (6 tests)
8. **Test_Empty_Simulation**: Empty simulation runs without errors
9. **Test_Task_Completion**: Task completes within its computation time
10. **Test_EDF_Ordering**: Earlier deadline task runs first
11. **Test_Preemption**: Higher priority task preempts current task
12. **Test_Non_Preemptive**: Non-preemptive mode doesn't preempt
13. **Test_Deadline_Miss**: System detects deadline misses

### Advanced Feature Tests (4 tests)
14. **Test_EDF_VD_Virtual_Deadline**: EDF-VD applies scaling to high criticality tasks
15. **Test_Max_Tasks**: System handles maximum task limit (32)
16. **Test_Periodic_ReRelease**: Periodic tasks re-release at period intervals
17. **Test_Mixed_Criticality_Schedulability**: Mixed criticality schedulability

### Running Tests

```bash
make test
```

Or manually:
```bash
mkdir -p obj bin
gprbuild -P tests/test_runner.gpr
./bin/edf_tests
```

Test output shows PASS/FAIL for each test with a summary at the end.

## Demonstration Programs

The `main.adb` file contains 5 demonstration scenarios:

1. **Basic Periodic Tasks**: Simple periodic task set with different periods
2. **Mixed Periodic and Aperiodic Tasks**: Combination of periodic and aperiodic tasks
3. **EDF-VD (Mixed Criticality)**: Demonstrates virtual deadline scaling
4. **Non-Preemptive EDF**: Shows non-preemptive scheduling behavior
5. **Overloaded System**: Demonstrates deadline misses in overloaded systems

Run the demonstration:
```bash
make run
```

Or manually:
```bash
mkdir -p obj bin
gprbuild -P edf_demo.gpr
./bin/main
```

## API Reference

### Types

```ada
-- Time representation
type Time_Unit is new Natural;

-- Task identifier
type Task_ID is new Positive;

-- Task classification
type Task_Type is (Aperiodic, Periodic);

-- Criticality levels
type Criticality_Level is (Low, High);

-- Scheduling variants
type Scheduling_Variant is (
   Standard_Preemptive,
   Standard_Non_Preemptive,
   EDF_VD
);

-- Task configuration
type Task_Config is record
   ID               : Task_ID;
   Type_Of_Task     : Task_Type;
   Criticality      : Criticality_Level;
   Release_Time     : Time_Unit;
   Computation_Time : Time_Unit;
   Deadline         : Time_Unit;  -- Relative deadline from release
   Period           : Time_Unit;  -- Only for Periodic tasks
end record;
```

### Procedures and Functions

```ada
-- Initialize the scheduler
procedure Initialize (Variant : Scheduling_Variant);

-- Add a task to the system
procedure Add_Task (Config : Task_Config);

-- Check if the task set is schedulable (for periodic tasks)
function Is_Schedulable return Boolean;

-- Run the simulation for a specified number of time units
procedure Run_Simulation (Ticks : Time_Unit);
```

## Implementation Details

### EDF Algorithm

The Earliest Deadline First algorithm schedules tasks based on their absolute deadlines. At any moment, the task with the earliest deadline is executed.

### Preemptive vs Non-Preemptive

- **Preemptive**: A newly arrived task with an earlier deadline can preempt the currently running task
- **Non-Preemptive**: Once a task starts execution, it runs to completion without preemption

### EDF-VD (Virtual Deadlines)

For mixed criticality systems, high criticality tasks have their deadlines scaled by a factor (default 0.5). This gives them effectively earlier deadlines, ensuring they get priority.

### Schedulability Test

The Liu & Layland bound is used: for periodic tasks, the system is schedulable if:

```
Sum over all periodic tasks of (Computation_Time / Period) <= 1.0
```

Note: This is a sufficient but not necessary condition for EDF schedulability.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
