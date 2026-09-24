# Task Scheduling Algorithms in Ada 2023

## Project Overview
This repository provides an automated planning and scheduling package implemented in strict Ada 2023. It explores CPU and real-time task scheduling policies, handling dynamic sequences of incoming tasks characterized by arrival times, execution bursts, and completion deadlines. 

## Features
* **First-Come, First-Served (FCFS):** Non-preemptive scheduling respecting strict arrival order.
* **Shortest Job Next (SJN):** Non-preemptive, executing the task with the smallest burst time from the available queue.
* **Shortest Remaining Time First (SRTF):** Preemptive scheduling algorithm that interrupts executing workloads if a newly arriving task has a shorter remaining burst.
* **Earliest Deadline First (EDF):** Preemptive scheduling optimized for deadline completion, pivoting runtime contexts dynamically towards impending deadlines.
* **Safety Contexts:** Robust parameter validation and constraint protections guarding against out-of-order execution, invalid state parameters, and logical underflows.

## Usage
Run `make test` from the root directory. The build configuration uses GNAT with strict warnings enabled (-gnatwa) and Ada 2022/2023 constructs (-gnat2022). It dynamically links the standalone test harness without requiring a classic `main.adb`. 
Expected output demonstrates the individual assertions passing followed by:
`===  42 passed,  0 failed ===`

## Testing
The standalone `tests.adb` suite drives functional verification across 13 diverse domains covering 42 assertions. Test categories validate algorithm-specific prioritization heuristics, extensive preemption and contextual state merging, data gap accommodations, deterministic tie-breaking logic, and programmatic exception triggers across all four primary API entry points.

## Building
* Prerequisites: GNAT compiler with make utility.
* Compile and Run: `make test`
* Clean Build: `make clean`
