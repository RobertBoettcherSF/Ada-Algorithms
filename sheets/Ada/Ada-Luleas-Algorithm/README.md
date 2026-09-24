# Ada-Luleas-Algorithm

Ada implementation of the **Luleå Algorithm** for efficient IPv4 routing table lookups.

---

## Project Overview

This project implements the **Luleå Algorithm**, a technique for storing and searching internet routing tables efficiently. The algorithm was designed by Degermark et al. (1997) at Luleå University of Technology and is optimized for **longest prefix matching (LPM)** in IPv4 routing tables.

### Key Features
- **Memory Efficiency**: Uses ~4-5 bytes per entry for large routing tables, allowing the entire data structure to fit into the processor's cache.
- **Fast Lookups**: Performs prefix matching in constant time using a compressed 3-level trie structure.
- **Static Structure**: The original algorithm is static (cannot be easily modified), but this implementation includes a **Hybrid Tree LPM** variant that supports dynamic updates.

### Implemented Variants
1. **Original Luleå Algorithm**: Static, memory-efficient, no dynamic updates.
2. **Sundström's 2x Speedup**: Optimized version with caching for faster lookups.
3. **Hybrid Tree LPM**: Supports dynamic updates and IPv6 (experimental).

---

## Features

### Core Functionality
- **Preprocessing**: Splits overlapping prefixes and completes the prefix tree to ensure correctness.
- **Trie Construction**: Builds a 3-level compressed trie for efficient lookups:
  - **Level 1**: Handles the first 16 bits of the IPv4 address.
  - **Level 2**: Handles bits 17-24 (8 bits).
  - **Level 3**: Handles bits 25-32 (8 bits).
- **Lookup**: Performs longest prefix matching (LPM) for any IPv4 address.

### Data Structures
- **Bit Vector**: 65,536 bits (1 bit per 16-bit prefix).
- **Base Indexes**: For every 64-bit subsequence in the bit vector.
- **Code Words**: 16-bit values (10-bit value + 6-bit offset).
- **Maptable**: 678 × 16 entries for 16-bit bitmask combinations.
- **Chunks**: For Levels 2 and 3 (8-bit prefix matching).

### Edge Cases Handled
- Empty routing tables.
- Overlapping prefixes (automatically split).
- Incomplete prefix trees (completed with dummy entries).
- Invalid inputs (e.g., invalid IPv4 addresses, prefix lengths > 32).

---

## Testing

### Test Philosophy
The test suite is designed under the **pessimistic assumption that the code is broken**. Each test aims to disprove this assumption by verifying correct behavior. A test **PASSes** when it disproves the assumption (i.e., the code works as expected).

### Test Categories
The test suite includes **13+ tests** covering the following categories:

1. **Functional Correctness**
   - IPv4 address conversion (string ↔ integer).
   - Prefix validation and overlap detection.
   - Bit extraction and manipulation.
   - Routing table preprocessing (splitting, completion).

2. **Error Handling**
   - Empty routing tables.
   - Invalid inputs (e.g., invalid IPv4 strings, prefix lengths > 32).
   - Lookup failures (no matching prefix).

3. **Edge Cases**
   - Single-entry routing tables.
   - Identical prefixes.
   - Boundary addresses (0.0.0.0, 255.255.255.255).

4. **Performance and Scalability**
   - Building tries with 100+ entries.
   - Multiple lookups on large routing tables.

5. **Variant-Specific Tests**
   - Original Luleå Algorithm.
   - Sundström's 2x Speedup (caching).
   - Hybrid Tree LPM (dynamic updates).

### Why These Tests Matter
- **Verification**: Ensures the code matches the algorithm's specifications (e.g., correct prefix matching, efficient lookups).
- **Validation**: Confirms the code meets its intended use (e.g., handling real-world routing tables, edge cases).
- **Reliability**: Proves the code works despite initial pessimistic assumptions, increasing confidence in its correctness.
- **Safety**: Validates error handling for critical systems (e.g., networking infrastructure).

### Test Execution
To run the test suite:
```bash
make test
```

Output will show **PASS/FAIL** for each assertion. Example:
```
========================================
TEST - IPv4 Address Conversion
========================================
  1.1 Assert IPv4_To_String(0) = " 0. 0. 0. 0"
     PASS - IPv4_To_String(0) = " 0. 0. 0. 0"
  1.2 Assert IPv4_To_String(2**32-1) = "255.255.255.255"
     PASS - IPv4_To_String(2**32-1) = "255.255.255.255"
```

---

## Usage

### Compilation

#### Using `gnatmake`
Compile the library and tests:
```bash
gnatmake -P lulea_algorithm.gpr
```

#### Using `make`
Compile everything (library + tests):
```bash
make all
```

Compile and run tests:
```bash
make test
```

Clean object and executable files:
```bash
make clean
```

### Execution

#### Run Tests
```bash
make test
```
or
```bash
./bin/tests
```

#### Example Usage (Ada Code)
```ada
with Lulea_Algorithm; use Lulea_Algorithm;

procedure Example is
   -- Define a routing table
   Routing_Table : Lulea_Algorithm.Routing_Table := (
      (Prefix => (Address => String_To_IPv4("192.168.0.0"), Length => 16), Info => (Next_Hop => String_To_IPv4("10.0.0.1"), Interface => 0, Metric => 1)),
      (Prefix => (Address => String_To_IPv4("192.168.1.0"), Length => 24), Info => (Next_Hop => String_To_IPv4("10.0.0.2"), Interface => 1, Metric => 2))
   );

   -- Build the trie
   Trie : Lulea_Trie := Original_Lulea.Build_Trie(Routing_Table);

   -- Lookup an address
   Address : IPv4_Address := String_To_IPv4("192.168.1.1");
   Result : Routing_Info := Original_Lulea.Lookup(Trie, Address);
begin
   null;
end Example;
```

### Input/Output Format
- **IPv4 Addresses**: Represented as 32-bit unsigned integers (`IPv4_Address` type).
- **Prefixes**: Combines an IPv4 address with a length (0-32 bits).
- **Routing Info**: Includes next hop (IPv4 address), interface (integer), and metric (integer).

---

## File Structure

```
RobertBoettcherSF__Ada-Luleas-Algorithm/
├── lulea_algorithm.ads      # Package specification (types, exceptions, declarations)
├── lulea_algorithm.adb      # Package body (implementations)
├── lulea_algorithm.gpr      # GNAT Project File
├── tests.adb                # Test suite (13+ tests)
├── Makefile                 # Compilation and testing
├── bin/                     # Executables
├── obj/                     # Object files
└── README.md                # Documentation
```

---

## References

- [Luleå Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Lule%C3%A5_algorithm)
- Degermark, M., Brodnik, A., Carlsson, S., Pink, S. (1997). *Small forwarding tables for fast routing lookups*. ACM SIGCOMM.
- Sundström, M. (2007). *Time and Space Efficient Algorithms for Packet Classification and Forwarding* (PhD Thesis). Luleå University of Technology.

---

## License

This project is licensed under the terms of the **MIT License**.
