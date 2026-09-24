# Data-Flow Analysis Engine in Ada 2023

## Project Overview
This project provides a complete, robust implementation of traditional Data-Flow Analysis on Control Flow Graphs (CFG). It computes properties about the dynamic behavior of programs at compile-time by implementing Kildall's iterative data-flow framework across basic blocks, supporting both forward and backward directions with both may and must confluence operators.

## Features
* Reaching Definitions: Forward, May-analysis computing which variable definitions reach each point in the CFG.
* Live Variables: Backward, May-analysis determining variables potentially read before being overwritten.
* Available Expressions: Forward, Must-analysis identifying expressions evaluated on every incoming path without redefinition.
* Very Busy Expressions: Backward, Must-analysis tracking expressions guaranteed to be evaluated along all execution paths before operand mutation.
* Strong Typing: Dimensioned CFG structures parameterized by custom ID types via discriminants to prevent index confusion.
* Ada Contract Aspects: Public operations annotated with Pre conditions and Global null annotations to enforce interface contracts.

## Usage
Build and run the test driver using the provided Makefile:

make test

Expected output:

Running tests...
--- Starting Data-Flow Analysis Test Suite ---
TEST 1 — Reaching Definitions (Linear)
  PASS — 1.1 Fact 1 reaches Node 2 In
  PASS — 1.2 Fact 1 killed, does not reach Node 3 In
  PASS — 1.3 Fact 2 reaches Node 3 In
TEST 2 — Reaching Definitions (Branch)
  PASS — 2.1 Fact 1 reaches Node 2 In via branch
  PASS — 2.2 Fact 1 reaches Node 3 In via branch
  PASS — 2.3 Fact 2 is never generated
...
=== 39 passed, 0 failed ===

## Testing
The standalone test executable (`tests.adb`) verifies correctness across four core dimensions:
* Functional Correctness: Validates data-flow equations across standard linear pipelines, conditional branches, and cyclical loops.
* Meet Operators: Confirms proper set union (May) and set intersection (Must) behavior across merge and split points.
* Edge Cases: Exercises single-node graphs, fully disconnected components, and graphs with zero gen operations.
* Error Handling & Invariants: Verifies dimension constraint preconditions and validates detection of simultaneous gen/kill conflicts via Graph_Conflict_Error.

## Building
* Prerequisites: GNAT compiler (GCC-based GNAT or GNAT Pro) supporting Ada 2022 / Ada 2023 (ISO/IEC 8652:2023).
* Build Tool: gnatmake or gprbuild.
* Compiler Flags: `-gnatwa -gnat2022` for strict warning compliance.
