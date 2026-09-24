# Sort-Merge Join Algorithm in Ada

## Project Overview
This repository implements the **Sort-Merge Join** scheduling/relational algorithm natively in Ada. Used widely in relational databases, the algorithm accepts two input relations, sorts them based on a designated join key (if not pre-sorted), and efficiently merges matching elements via pointers. 

## Features
- **Standard Inner Join**: Complete implementation with backtracking to appropriately yield Cartesian products for Many-to-Many matching relationships.
- **Unique-Key Variant**: A highly optimized variant enforcing one-to-many/one-to-one mapping conditions on the Left relation, sidestepping backtracking overhead entirely.
- **Dynamic Preemption (Auto-Sort)**: Preemptive toggling allowed (`Auto_Sort => True`) using generic standard-library array sorts.
- **Strongly Typed Output**: Dynamically sized result outputs utilizing `Ada.Containers.Vectors` tied strictly to application-defined tuples.

## Testing
Adhering to strict **Verification and Validation (V&V)** standards, we presume the code is faulty until proven functional. The test framework acts as the mechanism to forcefully disprove pessimistic assumptions across:

- **Functional Correctness Tests**: Proves one-to-one, one-to-many, and overlapping key mappings correctly merge.
- **Cartesian Fault Verification**: Ensures complex Many-to-Many duplication generates precisely N*M tuples, ensuring data mapping logic retains data integrity.
- **Error Handling & Exceptions**: Verifies the strict enforcement of preconditions (raising `Unsorted_Relation_Error` for unsorted logic, and `Non_Unique_Key_Error` for incorrect variant invocation).
- **Edge Conditions**: Proves stability across zero-length arrays, null outcomes, and bounds handling like negative indices.

*Why these matter:* Under critical system architecture, an algorithm must predictably halt or raise exceptions under bad inputs rather than generating silent logical errors (Validation). The test suite structurally guarantees that every variant of the implementation adheres exactly to standard relational theory behaviors (Verification).

## Usage

### Compilation
A standard POSIX Makefile is provided. Build both the test harness and the main demo program by executing:
```bash
make all
