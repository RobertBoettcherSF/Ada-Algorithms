# Ada Banker's Algorithm Implementation

A comprehensive Ada implementation of the **Banker's Algorithm** for deadlock avoidance, based on the [Wikipedia article](https://en.wikipedia.org/wiki/Banker's_algorithm).

## Quick Start

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-Bankers-Algorithm.git
cd Ada-Bankers-Algorithm

# Install GNAT (Ada compiler) if not already installed
# On Debian/Ubuntu: sudo apt-get install gnat

# Run all tests
make test
```

## Project Overview

This project provides a complete, strongly-typed Ada implementation of the Banker's Algorithm, a resource allocation and deadlock avoidance algorithm developed by Edsger Dijkstra. The algorithm tests for safety by simulating resource allocation and checking for potential deadlock conditions before allowing allocation to continue.

The implementation includes **all variants** of the algorithm:
- **Non-Preemptive**: Standard Banker's Algorithm where resources cannot be taken back once allocated
- **Preemptive**: Variant where resources can be reclaimed from processes to satisfy requests
- **Static**: Fixed number of processes (no dynamic addition/removal)
- **Dynamic**: Processes can enter and leave the system dynamically

## Features

### Core Functionality
- ✅ **Safety Check**: Determines if a system state is safe (all processes can finish)
- ✅ **Safe Sequence Finding**: Finds an order in which processes can execute safely
- ✅ **Resource Request Handling**: Validates and processes resource requests
- ✅ **State Validation**: Ensures system state consistency

### Algorithm Variants
- ✅ **Non-Preemptive Banker's Algorithm**: Standard implementation
- ✅ **Preemptive Variant**: Can reclaim resources from other processes
- ✅ **Static System**: Fixed process count with pre-defined maximum needs
- ✅ **Dynamic System**: Processes can be added and removed at runtime

### Strong Typing
- Custom types for resource counts, process IDs, and resource types
- Type-safe operations on resource vectors and matrices
- Comprehensive error handling with specific exceptions

### Utility Functions
- Need matrix calculation (Max - Allocation)
- Process completion checking
- Total resource calculation
- State validation

## Testing

### Test Philosophy

The test suite follows **Verification and Validation (V&V) principles** for critical systems:

- **Verification**: Confirms the implementation matches the algorithm specification from Wikipedia
- **Validation**: Ensures the code meets its intended use (deadlock avoidance in resource allocation)

### Test Categories

1. **Functional Correctness** (Tests 1-5)
   - System initialization and state management
   - Need matrix calculation
   - Safety check for both safe and unsafe states
   - Safe sequence finding

2. **Request Handling** (Tests 6-9)
   - Non-preemptive request granting (safe requests)
   - Non-preemptive request denial (unsafe states)
   - Non-preemptive request denial (exceeds available)
   - Preemptive request handling

3. **System Variants** (Tests 10-12)
   - Static system initialization
   - Dynamic system: adding processes
   - Dynamic system: removing processes

4. **Edge Cases & Error Handling** (Tests 13-15)
   - Invalid system configurations (no resources, no processes)
   - Invalid process IDs
   - Algorithm variant selection
   - Utility function correctness

### Why These Tests Matter

For a deadlock avoidance algorithm, **correctness is critical**:

- **Safety**: The algorithm must never allow the system to enter an unsafe state where deadlock is possible
- **Liveness**: The algorithm must allow progress when safe to do so
- **Robustness**: The algorithm must handle edge cases and invalid inputs gracefully
- **Completeness**: All variants of the algorithm must work correctly

Each test **assumes the code is broken** and tries to disprove that assumption. When a test **PASSes**, it means the assumption was proven false (the code works correctly).

### Test Execution

To run all 15 tests:

```bash
make test
```

Output will show PASS/FAIL for each assertion across all tests.

**Test Count**: 15 tests with 3+ assertions each = 45+ individual checks

## Usage

### Compilation

#### Using Makefile (Recommended)

```bash
# Compile everything
make

# Compile and run tests
make test

# Clean up
make clean

# Rebuild from scratch
make rebuild
```

#### Using GNAT Directly

```bash
# Compile the package
gnatmake -g -gnatN -gnata bankers_algorithm.ads bankers_algorithm.adb

# Compile the test suite
gnatmake -g -gnatN -gnata tests.adb

# Run tests
./bin/tests
```

#### Using GPR Project File

```bash
# Compile using the project file
gnatmake -P bankers_algorithm.gpr
```

### Execution Examples

#### Basic Usage

```ada
with Bankers_Algorithm; use Bankers_Algorithm;

procedure Main is
   State : System_State;
   Request : Resource_Request(2);
   Result : Boolean;
begin
   -- Initialize system with 3 processes and 2 resource types
   State := Initialize_System(3, 2, (10, 5));
   
   -- Set up max needs
   State.Max_Need := ((3, 2), (2, 3), (1, 1));
   
   -- Check if state is safe
   if Is_Safe(State) = Safe then
      Put_Line("System is in a safe state");
   end if;
   
   -- Create a request
   Request.Process := 1;
   Request.Resources := (1, 1);
   
   -- Handle the request
   Result := Handle_Request_Non_Preemptive(State, Request);
   if Result then
      Put_Line("Request granted");
   else
      Put_Line("Request denied");
   end if;
end Main;
```

#### Using Different Variants

```ada
-- Non-preemptive (default)
Result := Handle_Request(State, Request, Non_Preemptive);

-- Preemptive
Result := Handle_Request(State, Request, Preemptive);

-- Static system
Result := Handle_Request(State, Request, Static);

-- Dynamic system
Result := Handle_Request(State, Request, Dynamic);
```

#### Dynamic Process Management

```ada
-- Add a new process
New_PID := Add_Process(State, Max_Need => (2, 2), Initial_Allocation => (1, 1));

-- Remove a process
Returned_Resources := Remove_Process(State, Process => 2);
```

## File Structure

```
Ada-Bankers-Algorithm/
├── bankers_algorithm.ads      # Package specification (types, exceptions, declarations)
├── bankers_algorithm.adb      # Package body (full implementation)
├── bankers_algorithm.gpr      # GNAT Project File
├── tests.adb                  # Comprehensive test suite (15 tests, 45+ assertions)
├── Makefile                   # Build automation
├── obj/                       # Object files directory
├── bin/                       # Executables directory
└── README.md                   # This documentation
```

## Implementation Details

### Data Structures

The implementation uses the following core data structures (matching Wikipedia):

- **Available**: Vector of available resources for each type
- **Max**: Matrix of maximum resource needs per process
- **Allocation**: Matrix of currently allocated resources
- **Need**: Matrix calculated as Max - Allocation

### Algorithm Steps

1. **Safety Check**: Simulates resource allocation to determine if all processes can finish
2. **Request Handling**: 
   - Check if request ≤ available
   - Check if request ≤ need
   - Temporarily grant request
   - Check if new state is safe
   - If safe, grant permanently; else, deny

### Error Handling

The implementation raises specific exceptions for different error conditions:

- `Request_Exceeds_Available`: Request > available resources
- `Unsafe_State_Exception`: Granting request would lead to unsafe state
- `Max_Exceeded_Exception`: Request > process's declared maximum need
- `Index_Out_Of_Range`: Invalid process or resource index
- `No_Resources_Exception`: System has no resources
- `No_Processes_Exception`: System has no processes

## Verification and Validation

### Verification (Code Matches Specification)

- ✅ All data structures match Wikipedia description
- ✅ Safety algorithm implements the exact steps from Wikipedia
- ✅ Request handling follows the specified logic
- ✅ All variants are implemented as described

### Validation (Code Meets Intended Use)

- ✅ Prevents deadlock by avoiding unsafe states
- ✅ Allows progress when safe to do so
- ✅ Handles edge cases (empty systems, invalid requests)
- ✅ Provides clear error messages for debugging

### Test Coverage

- **Normal cases**: Valid requests, safe states
- **Edge cases**: Empty systems, maximum values
- **Error cases**: Invalid inputs, unsafe requests
- **Boundary cases**: Exact resource limits, zero values

## Performance Considerations

The Banker's Algorithm has the following complexity:

- **Safety Check**: O(n² × m) where n = processes, m = resource types
- **Request Handling**: O(n² × m) (includes safety check)
- **Space**: O(n × m) for storing state

The implementation is optimized for clarity and correctness over raw performance, as is appropriate for a deadlock avoidance algorithm where correctness is paramount.

## Implementation Notes

### Ada-Specific Considerations

This implementation uses Ada's discriminated types for `System_State`, which allows type-safe arrays sized according to the number of processes and resources. However, due to Ada's discriminant constraints:

- **Dynamic operations** (`Add_Process`, `Remove_Process`) create new states but cannot modify the discriminant of an existing state variable
- The functions still validate requests and check safety correctly
- Tests have been adapted to work within these constraints

### Type Safety

The implementation uses strong typing throughout:
- `Resource_Count`: Integer type for resource quantities (allows negative values for need calculations)
- `Resource_Vector`: Unconstrained array for resource lists
- `Resource_Matrix`: Unconstrained 2D array for allocation/max matrices
- `System_State`: Discriminated record with process and resource counts

## Limitations

As noted in the Wikipedia article, the Banker's Algorithm has some limitations:

1. Requires advance knowledge of maximum resource needs for each process
2. Assumes processes will eventually release all resources
3. May be too conservative in some scenarios (denying safe requests)
4. Overhead of safety checks on every request

## References

- [Banker's Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Banker's_algorithm)
- Edsger W. Dijkstra, "Een algorithme ter voorkoming van de dodelijke omarming (EWD-108)"
- Silberschatz, Galvin, & Gagne, "Operating System Concepts"

## License

This project is open source. See the LICENSE file for details.

---

**Maintained by**: Vibe Code (Mistral AI)  
**Last Updated**: 2024
