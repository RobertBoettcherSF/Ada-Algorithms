# Ada LST Scheduler

A Least Slack Time (LST) scheduling algorithm implementation in Ada. This project demonstrates both **Preemptive (Strict LST)** and **Non-Preemptive (Uninterruptible)** scheduling modes for real-time systems.

## Features

- Implements Least Slack Time scheduling algorithm
- Supports both Periodic and Sporadic job categories
- Includes acceptance test for sporadic jobs with hard deadlines
- Demonstrates preemptive and non-preemptive scheduling modes
- Shows slack time calculation and task execution in real-time simulation

## Prerequisites

- [GNAT](https://www.adacore.com/) (GNU Ada Compiler) - part of GCC

### Installation

**Ubuntu/Debian:**
```bash
sudo apt-get install gnat
```

**macOS (Homebrew):**
```bash
brew install gnat
```

**Windows:** Download from [AdaCore](https://www.adacore.com/download) or use [Alire](https://alire.ada.dev/)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-lds-scheduler.git
cd Ada-lds-scheduler

# Build and run
make
```

Or manually:
```bash
gprbuild -P lst_scheduler.gpr
./obj/main
```

## Project Structure

- `lst_scheduler.ads` - Package specification with types and procedure declarations
- `lst_scheduler.adb` - Package implementation with LST algorithm
- `main.adb` - Main program that runs the demo
- `lst_scheduler.gpr` - GNAT Project file for compilation

## Demo Output

The demo runs two simulations:

1. **Preemptive Mode (Strict LST)** - Tasks can be interrupted if a task with less slack becomes available
2. **Non-Preemptive Mode** - Once a task starts, it runs to completion

Each simulation shows:
- Current time
- Which task is executing
- The slack time for the current task
- Remaining execution time
- Task completion notifications

## Algorithm Details

### Least Slack Time (LST)
LST is a dynamic priority scheduling algorithm that assigns priorities based on **slack time** - the time remaining until a task's deadline minus its remaining execution time.

**Slack = Deadline - Current_Time - Remaining_Time**

The task with the **least slack** has the highest priority.

### Acceptance Test
For sporadic jobs, the acceptance test checks if:
```
Deadline >= Arrival + Burst
```
If this condition fails, the sporadic task is rejected to prevent deadline misses.

## Usage

To use the scheduler in your own code:

```ada
with LST_Scheduler;

procedure My_Program is
   Sched : LST_Scheduler.Scheduler(Max_Tasks => 10);
begin
   Sched.Init;
   
   -- Add periodic tasks
   Sched.Add_Task(ID => 1, Category => LST_Scheduler.Periodic, 
                  Arrival => 0, Burst => 5, Deadline => 10);
   
   -- Add sporadic tasks (will be acceptance tested)
   Sched.Add_Task(ID => 2, Category => LST_Scheduler.Sporadic,
                  Arrival => 2, Burst => 3, Deadline => 8);
   
   -- Run simulation
   Sched.Run_Simulation(Mode => LST_Scheduler.Preemptive, 
                        Total_Time => 20);
end My_Program;
```

## License

MIT License - see LICENSE file for details.
