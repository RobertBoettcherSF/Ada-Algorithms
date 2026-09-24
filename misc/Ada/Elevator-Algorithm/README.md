-- Version: 0.01
# Ada Elevator Algorithm

Ada Implementation of Disk Scheduling Algorithms (Elevator Algorithm and variants).

## Algorithms Implemented

1. **SCAN** (Elevator Algorithm) - The arm sweeps to the extreme end of the disk before reversing direction
2. **C-SCAN** (Circular SCAN) - Sweeps to the end, then jumps to the other end without servicing requests
3. **LOOK** - Similar to SCAN, but only goes as far as the last request before reversing
4. **C-LOOK** (Circular LOOK) - Similar to C-SCAN, but only goes to the furthest request before jumping
5. **F-SCAN** - Uses two queues to prevent starvation

## Test Suite

The repository includes a comprehensive test suite with **45+ tests** across 8 categories:

- SCAN Algorithm Tests (8 tests)
- C-SCAN Algorithm Tests (5 tests)
- LOOK Algorithm Tests (6 tests)
- C-LOOK Algorithm Tests (5 tests)
- F-SCAN Algorithm Tests (4 tests)
- Assumption Validation Tests (4 tests)
- Tests to be Proven False (6 tests)
- Algorithm Comparison Tests (4 tests)
- Edge Case Tests (3 tests)

### Running Tests

```bash
# Build and run all tests
gprbuild -P test_project.gpr
./obj/run_tests
```

### Expected Output

```
================================================================================
DISK SCHEDULING ALGORITHMS - ADA TEST SUITE
================================================================================

--- SCAN Algorithm Tests ---
  PASS: SCAN_Basic_UP
  PASS: SCAN_Empty
  ...

--- Tests to be Proven False ---
  PASS: SCAN_Includes_Max
  PASS: LOOK_No_Max
  ...

================================================================================
TEST SUMMARY: 45/45 passed
================================================================================

ALL TESTS PASSED
```

## Project Structure

```
Ada-Elevator-Algorithm/
├── disk_scheduling.ads          # Algorithm specifications (Version: 0.01)
├── disk_scheduling.adb          # Algorithm implementations (Version: 0.01)
├── disk_scheduling.gpr          # Main project file (Version: 0.01)
├── test_project.gpr             # Test project file (Version: 0.02)
├── README.md                    # This file (Version: 0.01)
├── LICENSE
├── .gitignore
└── tests/
    ├── test_disk_scheduling.ads  # Test specifications (Version: 0.12)
    ├── test_disk_scheduling.adb  # Test implementations (Version: 0.12)
    └── run_tests.adb             # Main test executable (Version: 0.01)
```

## Version Tracking

All files include version headers in the format `-- Version: X.XX`. Versions are incremented by +0.01 when a file is edited.

## Requirements Met

✅ **Pure Ada** - No Python, only gprbuild required
✅ **45+ tests** covering all algorithms and edge cases
✅ **Tests to be proven false** - 6 tests that validate wrong assumptions are false
✅ **Version tracking** - All files have version headers
✅ **No compiler warnings** - Clean compilation
✅ **All tests pass** - 45/45 tests pass

## Building

```bash
# Build the main project
gprbuild -P disk_scheduling.gpr

# Build and run tests
gprbuild -P test_project.gpr
./obj/run_tests
```

## License

This project is licensed under the MIT License - see LICENSE file for details.
