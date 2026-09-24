# Ada-arc-cache

Ada implementation of Generic Adaptive Replacement Cache (ARC) algorithm.

## Overview

This package provides a generic implementation of the Adaptive Replacement Cache (ARC) algorithm as described by Nimrod Megiddo and Dharmendra Modha. The ARC algorithm is a self-tuning, low overhead cache replacement algorithm that outperforms LRU and other traditional algorithms.

Additionally, this implementation supports the ZFS variant which explicitly allows for locked pages that cannot be vacated while in use, making it suitable for use cases similar to the OpenZFS L2ARC.

## Features

- **Standard ARC Algorithm**: Full implementation of the adaptive replacement cache algorithm
- **ZFS Variant Support**: Locked pages that cannot be evicted while in use
- **Generic Design**: Works with any key and value types
- **Ada 2012 Compatible**: Uses modern Ada features
- **Comprehensive Testing**: 15+ test suites covering all functionality

## Quick Start

### Building the Library

```bash
# Create required directories
mkdir -p obj bin

# Build the library
gnatmake -P arc_cache.gpr

# Build the tests
gnatmake -P test_arc_cache.gpr
```

### Running Tests

```bash
# Run all tests
./bin/test_arc_cache
```

## Usage

### Basic Usage

```ada
with ARC_Cache;

-- Define hash and equality functions for your key type
function Hash (Key : String) return Ada.Containers.Hash_Type is
   -- Your hash implementation
;

function "=" (Left, Right : String) return Boolean is
begin
   return Left = Right;
end "=";

-- Instantiate the cache package
package String_Integer_Cache is new ARC_Cache
   (Key_Type => String,
    Value_Type => Integer,
    Hash => Hash,
    "=" => "=");

-- Use the cache
declare
   Cache : String_Integer_Cache.Cache (Capacity => 100);
begin
   -- Put a value
   String_Integer_Cache.Put (Cache, "my_key", 42);
   
   -- Get a value
   declare
      Value : Integer;
      Found : Boolean := String_Integer_Cache.Get (Cache, "my_key", Value);
   begin
      if Found then
         -- Use Value
      end if;
   end;
end;
```

### Using Locked Pages (ZFS Variant)

```ada
-- Put a locked value (cannot be evicted)
String_Integer_Cache.Put_Locked (Cache, "locked_key", 100);

-- Get and lock a value
declare
   Value : Integer;
   Found : Boolean := String_Integer_Cache.Get_Locked (Cache, "some_key", Value);
begin
   if Found then
      -- Value is now locked and cannot be evicted
   end if;
end;

-- Unlock a value
String_Integer_Cache.Unlock (Cache, "locked_key");

-- Check if a key is locked
if String_Integer_Cache.Is_Locked (Cache, "locked_key") then
   -- Key is locked
end if;
```

## Test Suite

The test suite (`test_arc_cache.adb`) provides comprehensive testing with 100+ individual test assertions across 18 test categories:

### Test Categories

1. **Basic Functionality Tests** (TEST 1-3)
   - Basic Put and Get operations
   - Cache capacity and eviction
   - Multiple key types (String, Integer)

2. **Locked Page Functionality Tests** (TEST 4-6)
   - Put_Locked and Get_Locked operations
   - Locked pages prevent eviction
   - Cache_Full_Of_Locked_Pages exception handling
   - Mixed locked and unlocked operations

3. **ARC Algorithm Properties Tests** (TEST 7-9)
   - P parameter adaptation
   - Ghost cache behavior (B1 and B2 lists)
   - Cache hit and miss patterns
   - Sequential and repeated access patterns

4. **Edge Cases and Error Conditions Tests** (TEST 10-13)
   - Empty cache operations
   - Single capacity cache
   - Same key operations
   - Boundary conditions (large capacity, zero capacity)

5. **Performance and Stress Tests** (TEST 14-15)
   - Many sequential operations
   - Interleaved operations
   - Cache consistency under pressure

6. **Assumption Violation Tests** (TEST 16-18)
   - Tests designed to prove assumptions wrong
   - Cache behavior assumptions
   - Capacity management assumptions
   - Lock behavior assumptions

### Running Specific Tests

The test runner executes all test suites automatically. Each test:
- Prints clear pass/fail status
- Provides detailed error messages for failures
- Tracks success rate
- Generates a comprehensive summary

### Test Output Format

```
========================================
TEST SUITE: Basic Functionality Tests
========================================

--- TEST 1 - Basic Put and Get Operations ---
[PASS] 1.1.1 - Get returns True for existing key
[PASS] 1.1.2 - Retrieved value matches stored value
[FAIL] 1.2.1 - Get returns False for non-existent key (Expected: False, Actual: True)
...

========================================
TEST SUMMARY
========================================
Total Tests: 100
Passed: 98
Failed: 2
Success Rate:  98.00%
========================================
```

## Directory Structure

```
Ada-arc-cache/
├── arc_cache.adb          # Implementation
├── arc_cache.ads          # Specification
├── arc_cache.gpr          # Library project file
├── test_arc_cache.adb     # Comprehensive test suite
├── test_arc_cache.gpr     # Test project file
├── README.md              # This file
├── LICENSE                # License information
├── obj/                   # Object files (created during build)
└── bin/                   # Executables (created during build)
```

## Algorithm Details

The ARC algorithm maintains four lists:
- **T1**: Recently used items (MRU to LRU)
- **T2**: Recently used items that were previously evicted (MRU to LRU)
- **B1**: Recently evicted items from T1 (ghost cache)
- **B2**: Recently evicted items from T2 (ghost cache)

The algorithm adapts the target size of T1 (parameter P) based on cache hits in the ghost caches, allowing it to dynamically adjust between LRU and MRU behavior based on access patterns.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite to ensure all tests pass
5. Submit a pull request

## Building from Source

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-arc-cache.git
cd Ada-arc-cache

# Create directories (if not already present)
mkdir -p obj bin

# Build the library
gnatmake -P arc_cache.gpr

# Build and run tests
gnatmake -P test_arc_cache.gpr
./bin/test_arc_cache
```

## Troubleshooting

### "object directory not found" error

```bash
mkdir obj
```

### "exec directory not found" error

```bash
mkdir bin
```

### Compiler warnings

The code is designed to compile with `-gnatwa` (all warnings enabled). Some warnings about unused variables may appear - these are intentional and indicate areas where the code could be optimized further.

## References

- Megiddo, N., & Modha, D. S. (2003). ARC: A self-tuning, low overhead replacement cache. FAST.
- Original ARC algorithm paper: https://www.usenix.org/legacy/publications/library/proceedings/fast03/tech/megiddo.html
