# Vector Clocks Algorithm

A robust, strongly-typed **Ada** implementation of the **Vector Clocks** algorithm for distributed systems.

## Overview

Vector clocks are a mechanism for capturing **causality** and **partial ordering** of events in distributed systems. Unlike Lamport timestamps (which only provide total ordering), vector clocks ensure that if `Clock(A) < Clock(B)`, then event A **definitively happened before** event B. This makes them essential for debugging distributed systems, detecting race conditions, and implementing consistent distributed snapshots.

This implementation follows the formal definitions from:
- **Fidge, C. J.** (1988). "Timestamps in a Distributed System: A Formal Specification and Implementation".
- **Mattern, F.** (1988). "Virtual Time and Global States of Distributed Systems".

## Features

This implementation provides all operational variants and partial ordering comparisons:

| Feature | Description |
|---------|-------------|
| **Initialization** | Zeroes out local vector state and enforces safe bounds on Process IDs |
| **Internal Event** | Process experiences an internal event and increments its own clock |
| **Send Message** | Process increments its clock and returns a copy as message payload |
| **Receive Message** | Process merges incoming vector via element-wise `Max()`, then increments local time |
| **Happens-Before (`<`)** | Determines strict causal priority between two vectors |
| **Less-Than-or-Equal (`<=`)** | Determines non-strict causal ordering |
| **Concurrency (`Are_Concurrent`)** | Detects when two vectors have no causal relationship (disjoint timelines) |

## Project Structure

```
Ada-Vector-Clocks/
├── README.md           # This file
├── LICENSE             # MIT License
├── Makefile            # Build configuration
├── vector_clocks.gpr   # GNAT Project file
├── tests.adb           # Comprehensive test suite
├── src/
│   ├── vector_clocks.ads   # Package specification (types, interfaces)
│   ├── vector_clocks.adb   # Package implementation
│   └── main.adb            # Simple demonstration executable
├── obj/                # Object files (generated)
└── bin/                # Binaries (generated)
```

## Installation

### Prerequisites

You need the **GNAT Ada toolchain** installed:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install gnat
```

**Fedora/RHEL:**
```bash
sudo dnf install gcc-gnat
```

**macOS (Homebrew):**
```bash
brew install gnat
```

**Windows:**
- Download and install [GNAT Community Edition](https://www.adacore.com/download) from AdaCore

Verify installation:
```bash
gnatmake --version
```

## Usage

### Quick Start

Clone the repository and build:
```bash
git clone https://github.com/RobertBoettcherSF/Ada-Vector-Clocks.git
cd Ada-Vector-Clocks
make all      # Build both main executable and test suite
make test     # Compile and run all tests
make clean    # Remove generated files
```

### Code Examples

#### Basic Usage

```ada
with Vector_Clocks; use Vector_Clocks;

procedure Example is
   -- Create a process node for a system with 3 processes
   P1 : Process_Node(3);
   
   -- Initialize process with ID 1
   Setup(P1, 1);
   
   -- Process experiences an internal event
   Internal_Event(P1);
   
   -- Send a message (returns current clock state)
   declare
      Msg_Clock : Vector_Clock := Send_Message(P1);
   begin
      -- ... send Msg_Clock with your message payload ...
   end;
   
   -- Receive a message from another process
   declare
      Received_Clock : Vector_Clock(1..3) := (0, 1, 0);
   begin
      Receive_Message(P1, Received_Clock);
   end;
end Example;
```

#### Checking Causal Relationships

```ada
with Vector_Clocks; use Vector_Clocks;

procedure Check_Causality is
   Clock_A : Vector_Clock(1..2) := (2, 1);
   Clock_B : Vector_Clock(1..2) := (1, 2);
begin
   -- Check if A happened before B
   if Clock_A < Clock_B then
      Put_Line("A happened before B");
   end if;
   
   -- Check if A and B are concurrent (no causal relationship)
   if Are_Concurrent(Clock_A, Clock_B) then
      Put_Line("A and B are concurrent events");
   end if;
end Check_Causality;
```

#### Complete Message Passing Example

```ada
with Vector_Clocks; use Vector_Clocks;

procedure Message_Passing is
   -- Two processes in a distributed system
   Process_1 : Process_Node(2);
   Process_2 : Process_Node(2);
   
   -- Initialize processes
   Setup(Process_1, 1);
   Setup(Process_2, 2);
   
   -- Process 1 does some work
   Internal_Event(Process_1);
   Internal_Event(Process_1);
   
   -- Process 1 sends a message to Process 2
   declare
      Message_Clock : Vector_Clock := Send_Message(Process_1);
   begin
      -- Transmit Message_Clock with actual data...
      
      -- Process 2 receives the message
      Receive_Message(Process_2, Message_Clock);
      
      -- Now Process_2's clock reflects the merged state
   end;
end Message_Passing;
```

## Testing

### Verification & Validation Approach

This project uses a **pessimistic testing** methodology: the test suite fundamentally assumes the code is *incorrect* and only passes when assertions definitively disprove this assumption. This critical systems approach ensures reliability for mission-critical applications.

### Test Categories

| Category | Tests | Purpose |
|----------|-------|---------|
| **Initialization** | 1-2 | Validates setup, ID assignment, and boundary conditions |
| **Functional Correctness** | 3-5, 13 | Proves mathematical operations (max, increments) target correct elements |
| **Partial Ordering** | 6-10 | Validates causal detection (`<`, `<=`) and concurrency (`Are_Concurrent`) |
| **Error Handling** | 11-12 | Validates exception handling for invalid inputs |

### Running Tests

```bash
# Run all tests
make test

# Or manually
make bin/tests
./bin/tests
```

All 13+ tests must pass for the implementation to be considered correct.

## API Reference

### Types

#### `Vector_Clock`
An unconstrained array type representing a vector clock.
```ada
type Vector_Clock is array (Positive range <>) of Natural;
```

#### `Process_Node(Num_Processes : Positive)`
A process in the distributed system with a fixed-size vector clock.
```ada
type Process_Node (Num_Processes : Positive) is record
   ID    : Positive := 1;
   Clock : Vector_Clock (1 .. Num_Processes) := (others => 0);
end record;
```

### Exceptions

| Exception | Raised When |
|-----------|-------------|
| `Mismatched_Dimensions` | Vector clocks have different sizes during comparison or receive |
| `Invalid_Process_ID` | Process ID exceeds the declared number of processes |

### Procedures and Functions

#### `Setup(P : in out Process_Node; ID : Positive)`
Initializes a process with a given ID and zeroes its clock.
- **Parameters:**
  - `P`: The process node to initialize
  - `ID`: The process identifier (1 to Num_Processes)
- **Raises:** `Invalid_Process_ID` if ID > Num_Processes

#### `Internal_Event(P : in out Process_Node)`
Increments the process's own clock component.
- **Parameters:** `P`: The process experiencing the event

#### `Send_Message(P : in out Process_Node) return Vector_Clock`
Increments local clock and returns current state as payload.
- **Parameters:** `P`: The sending process
- **Returns:** Copy of the process's current vector clock

#### `Receive_Message(P : in out Process_Node; Msg_Clock : Vector_Clock)`
Merges incoming clock via element-wise max, then increments local clock.
- **Parameters:**
  - `P`: The receiving process
  - `Msg_Clock`: The vector clock from the received message
- **Raises:** `Mismatched_Dimensions` if clock sizes differ

#### `"<="(Left, Right : Vector_Clock) return Boolean`
Checks if Left is less-than-or-equal to Right (non-strict happens-before).
- **Returns:** True if all elements of Left ≤ corresponding elements of Right
- **Raises:** `Mismatched_Dimensions` if clock sizes differ

#### `"<"(Left, Right : Vector_Clock) return Boolean`
Checks if Left strictly happens before Right.
- **Returns:** True if Left ≤ Right and Left ≠ Right
- **Raises:** `Mismatched_Dimensions` if clock sizes differ

#### `Are_Concurrent(Left, Right : Vector_Clock) return Boolean`
Checks if two vectors represent concurrent (non-causally-related) events.
- **Returns:** True if neither Left ≤ Right nor Right ≤ Left
- **Raises:** `Mismatched_Dimensions` if clock sizes differ

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. Create a **feature branch** (`git checkout -b feature/amazing-feature`)
3. **Test** your changes (`make test` must pass)
4. **Commit** your changes with descriptive messages
5. **Push** to your fork
6. Open a **Pull Request**

### Code Style

- Follow **Ada best practices** (strong typing, proper use of discriminants)
- Use **descriptive names** for types, procedures, and variables
- **Comment** non-obvious logic and algorithmic decisions
- Include **parameter documentation** for public subprograms

### Testing

- All new features must include **comprehensive tests**
- Tests should follow the **pessimistic assumption** methodology
- Edge cases and boundary conditions must be tested

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the foundational work on vector clocks by Colin Fidge and Friedemann Mattern
- Built with **GNAT Ada** compiler
- Designed for **mission-critical distributed systems**
