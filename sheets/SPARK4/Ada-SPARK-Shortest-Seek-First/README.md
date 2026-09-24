# Ada-SPARK-Shortest-Seek-First
Ada SPARK Implementation of Shortest Seek First Algorithm; https://en.wikipedia.org/wiki/Shortest_seek_first

## Project Structure

```
.
├── sstf.ads                    # Package specification (SPARK)
├── sstf.adb                    # Package implementation (SPARK)
├── sstf.gpr                    # GPR project file
├── tests/                      # Comprehensive test suite
│   ├── sstf_tests.ads          # Test package specification
│   ├── sstf_tests.adb          # Test package with 10 test cases
│   ├── test_runner.adb         # Test runner program
│   └── test_runner.gpr         # Test project file
├── demo/                       # Demonstration programs
│   ├── sstf_demo.adb           # Interactive demo program
│   └── sstf_demo.gpr           # Demo project file
├── build.sh                    # Build script
└── README.md
```

## Building and Running

### Quick Start

```bash
./build.sh test    # Build and run comprehensive test suite
./build.sh demo    # Build and run demonstration program
./build.sh clean   # Clean build artifacts
```

### Manual Building

- **Run tests:**
  ```bash
  gprbuild -P tests/test_runner.gpr
  ./bin/test_runner
  ```

- **Run demo:**
  ```bash
  gprbuild -P demo/sstf_demo.gpr
  ./bin/sstf_demo              # Run predefined demos
  ./bin/sstf_demo interactive  # Run interactive demo
  ```

## Test Suite

The comprehensive test suite includes **10 test cases** covering:

- Single request verification
- Two requests with head in middle/at start
- Multiple requests with mixed positions
- All requests on one side of head
- Head exactly at request position
- Edge cases (head at track 0)
- Complex scenarios with 5+ requests

All tests verify that the SSTF algorithm correctly selects the closest request to the current head position.

## Demo Program

The demo program provides:

- **Predefined Demonstrations** - 5 different scenarios with explanations
- **Interactive Mode** - Enter your own head position and requests
- **Step-by-step Output** - Shows seek movement for each step
- **Total Seek Distance** - Calculates and displays total head movement

## SPARK Verification

The core SSTF algorithm is written in SPARK and includes:

- Preconditions for valid input parameters
- Postconditions for correct output
- Depends contracts for information flow
- Loop invariants for array index safety
- Type constraints to prevent buffer overflows

**GNATPROVE Status:** ✅ All checks pass at level 4 with no warnings

## Algorithm Description

The Shortest Seek First (SSTF) algorithm:

1. Start with the initial head position
2. Find the request closest to the current head position
3. Move the head to that request
4. Mark the request as serviced
5. Repeat until all requests are serviced

This minimizes the total seek time by always choosing the closest available request.

## License

MIT License
