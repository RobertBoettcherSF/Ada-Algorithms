# Ada Clock Replacement Algorithms

A comprehensive Ada 2012 implementation of various **Clock page replacement algorithms** for operating systems and memory management research. This library provides multiple page replacement strategies with a unified interface, making it easy to compare their behavior and performance.

## What This Code Does

This project implements **five different page replacement algorithms** that determine which page to evict from memory when a page fault occurs and the memory is full. Each algorithm uses a different strategy to minimize page faults and improve system performance.

### Implemented Algorithms

| Algorithm | Description | Key Parameter |
|-----------|-------------|---------------|
| **Standard Clock** | Basic second-chance algorithm using reference bits | None |
| **GCLOCK** | Generalized clock using counters instead of boolean bits | `Max_Count` (default: 2) |
| **WSClock** | Working Set Clock with aging based on time | `Tau` (default: 10) |
| **CAR** | Clock with Adaptive Replacement using two lists | None (adaptive) |
| **Clock-Pro** | Enhanced clock with Hot, Cold, and Test page categories | None |

## Project Structure

```
Ada-clock-replacement/
├── clock_algorithms.ads    # Algorithm type specifications
├── clock_algorithms.adb    # Algorithm implementations
├── clock_variants.gpr       # GNAT project configuration
├── Makefile                 # Build system
├── run_tests.adb            # Main test runner entry point
├── test_clock.adb           # Simple demonstration program
├── tests/
│   ├── clock_tests.ads      # Test framework specification
│   └── clock_tests.adb      # Test implementations (15 tests, 24 assertions)
├── obj/                     # Object files (tracked in git)
├── bin/                     # Binary files (tracked in git)
└── README.md
```

## Quick Start

### Prerequisites

- **GNAT (GNU Ada Compiler)** - Required to compile Ada code
  - Ubuntu/Debian: `sudo apt-get install gnat`
  - Fedora: `sudo dnf install gnat`
  - macOS (Homebrew): `brew install gnat`
  - Windows: Download from [libre.adacore.com](https://libre.adacore.com/)

### Building and Testing

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-clock-replacement.git
cd Ada-clock-replacement

# Build the library (no output = success)
make

# Run all 15 tests with 24 assertions
make tests

# Run simple demonstration
make test

# Clean build artifacts
make clean

# Full clean (including executables)
make clobber
```

## Understanding the Algorithms

### Common Interface

All algorithms inherit from `Base_Algorithm` and provide:

```ada
type Base_Algorithm is abstract tagged record
   Capacity    : Natural;      -- Maximum number of pages
   Page_Faults : Natural := 0; -- Count of page faults
   Accesses    : Natural := 0; -- Total memory accesses
end record;

-- Common operations
procedure Access_Page (Algo : in out Base_Algorithm; Page : Page_ID) is abstract;
function Get_Page_Faults (Algo : Base_Algorithm) return Natural;
function Get_Hit_Rate (Algo : Base_Algorithm) return Float;
```

### 1. Standard Clock (Second-Chance)

The basic clock algorithm maintains a circular list of pages with reference bits.

**How it works:**
- When a page is accessed, its reference bit is set to true
- On a page fault, the algorithm scans the circular list
- If a page's reference bit is true, it gets a "second chance" (bit is cleared, scan continues)
- If a page's reference bit is false, it is evicted

**Use case:** Simple, efficient page replacement with minimal overhead.

### 2. GCLOCK (Generalized Clock)

Extends the standard clock by using **counters** instead of boolean reference bits.

**How it works:**
- Each page has a counter (0 to Max_Count)
- On access, the counter is reset to Max_Count
- On each scan pass, counters are decremented
- A page is evicted when its counter reaches 0

**Use case:** Provides more fine-grained control over page lifetime. Higher Max_Count = more chances before eviction.

### 3. WSClock (Working Set Clock)

Adds **time-based aging** to the clock algorithm.

**How it works:**
- Each page tracks its last access time
- Uses a Tau (τ) parameter as the aging threshold
- Pages older than Tau are eligible for eviction
- Recently accessed pages (within Tau time units) are protected

**Use case:** Better for workloads with temporal locality, where recently used pages are likely to be reused.

### 4. CAR (Clock with Adaptive Replacement)

An adaptive algorithm that dynamically adjusts between LRU and FIFO behavior.

**How it works:**
- Maintains two lists: T1 (recently used) and T2 (less recently used)
- Uses two history caches: B1 and B2
- Dynamically adjusts the target size P for T1 based on cache hits in B1 and B2
- Pages in T1 get more chances than pages in T2

**Use case:** Adapts to changing workload patterns automatically.

### 5. Clock-Pro

An enhanced clock algorithm with three page categories.

**How it works:**
- Pages are categorized as Hot, Cold, or Test
- Maintains a single circular list with all categories
- Hot pages: Recently accessed, protected from eviction
- Cold pages: Not recently accessed, eligible for eviction
- Test pages: Being tested for potential promotion to Hot

**Use case:** Provides better performance by distinguishing between hot and cold pages.

## The Test Suite

### Overview

The project includes a **comprehensive test suite** with **15 tests** covering **24 assertions**. The tests verify the correctness of each algorithm and compare their behavior.

### Test Organization

```
Test 1: Standard Clock Algorithm (5 assertions)
  ├── 1.1: Empty access sequence
  ├── 1.2: Single page repeated access
  ├── 1.3: Page fault counting
  ├── 1.4: Hit rate calculation
  └── 1.5: Circular replacement behavior

Test 2: GCLOCK Algorithm (5 assertions)
  ├── 2.1: Empty access sequence
  ├── 2.2: Single page repeated access
  ├── 2.3: Page fault counting with counter
  ├── 2.4: Counter decrement on access
  └── 2.5: Higher count means longer survival

Test 3: WSClock Algorithm (3 assertions)
  ├── 3.1: Empty access sequence
  ├── 3.2: Recent access protection (Tau)
  └── 3.3: Tau expiration behavior

Test 4: Comparison Tests (2 assertions)
  ├── 4.1: Clock vs GCLOCK - Both produce faults
  └── 4.2: All algorithms produce faults
```

### What the Tests Verify

Each test verifies specific **assumptions** about the algorithm behavior. These assumptions could be proven false if the implementation is incorrect.

#### Assumptions About Clock Algorithm

1. **A1: Empty access has zero faults** - No page accesses should result in zero page faults
2. **A2: Single page has one fault** - Repeated access to the same page should only fault once
3. **A3: Fault counting is accurate** - A known reference string produces the expected number of faults
4. **A4: Hit rate is calculated correctly** - The hit rate percentage matches expected values
5. **A5: Circular replacement works** - When cache is full, pages are replaced in circular order

#### Assumptions About GCLOCK Algorithm

6. **A6: Empty access has zero faults** - Same as Clock for empty access
7. **A7: Single page has one fault** - Same as Clock for single page
8. **A8: Counter-based eviction** - GCLOCK should have same or fewer faults than Clock (more chances)
9. **A9: Counter decrements on scan** - Pages lose chances as the hand passes them
10. **A10: Higher Max_Count = longer survival** - Pages with higher Max_Count get more chances

#### Assumptions About WSClock Algorithm

11. **A11: Empty access has zero faults** - Same as other algorithms
12. **A12: Recent pages are protected** - Pages accessed within Tau time units should not be evicted
13. **A13: Tau expiration works** - Pages older than Tau should be eligible for eviction

#### Cross-Algorithm Assumptions

14. **A14: All algorithms handle faults** - Both Clock and GCLOCK should produce page faults
15. **A15: All algorithms are functional** - Clock, GCLOCK, and WSClock all produce faults when needed

### Why These Tests Matter

These tests verify that:
- **Basic functionality works**: Empty access, single page, fault counting
- **Algorithm-specific behavior is correct**: Counter decrement, Tau protection, circular scanning
- **Algorithms are comparable**: They all handle the same inputs and produce reasonable outputs
- **Edge cases are handled**: Empty sequences, full caches, repeated accesses

If any test fails, it means the corresponding assumption about the algorithm's behavior is **proven false**, indicating a bug in the implementation.

## Usage Examples

### Simple Usage

```ada
with Clock_Algorithms; use Clock_Algorithms;
with Ada.Text_IO; use Ada.Text_IO;

procedure Simple_Example is
   -- Create a Clock algorithm with capacity of 3 pages
   Algo : Clock_Algo := Init_Clock(3);
   
   -- Define a sequence of page accesses
   Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
begin
   -- Process each page access
   for P of Pages loop
      Access_Page(Algo, P);
   end loop;
   
   -- Display results
   Put_Line("Page Faults: " & Natural'Image(Get_Page_Faults(Algo)));
   Put_Line("Hit Rate: " & Float'Image(Get_Hit_Rate(Algo)));
end Simple_Example;
```

### Comparing Algorithms

```ada
with Clock_Algorithms; use Clock_Algorithms;
with Ada.Text_IO; use Ada.Text_IO;

procedure Compare_Algorithms is
   -- Create instances of different algorithms
   Clock_Algo : Clock_Algo := Init_Clock(100);
   GCLOCK_Algo : GCLOCK_Algo := Init_GCLOCK(100, 2);
   WSClock_Algo : WSClock_Algo := Init_WSClock(100, 10);
   
   -- Define a page access sequence (e.g., from a trace)
   Pages : constant array(1..1000) of Page_ID := 
     (1, 2, 3, 4, 5, 1, 2, 3, 4, 5, others => 1);
   
   Faults_Clock : Natural;
   Faults_GCLOCK : Natural;
   Faults_WSClock : Natural;
begin
   -- Run the same sequence through all algorithms
   for P of Pages loop
      Access_Page(Clock_Algo, P);
   end loop;
   Faults_Clock := Get_Page_Faults(Clock_Algo);
   
   for P of Pages loop
      Access_Page(GCLOCK_Algo, P);
   end loop;
   Faults_GCLOCK := Get_Page_Faults(GCLOCK_Algo);
   
   for P of Pages loop
      Access_Page(WSClock_Algo, P);
   end loop;
   Faults_WSClock := Get_Page_Faults(WSClock_Algo);
   
   -- Compare results
   Put_Line("Clock faults:   " & Natural'Image(Faults_Clock));
   Put_Line("GCLOCK faults:  " & Natural'Image(Faults_GCLOCK));
   Put_Line("WSClock faults: " & Natural'Image(Faults_WSClock));
end Compare_Algorithms;
```

### Using Different Parameters

```ada
with Clock_Algorithms; use Clock_Algorithms;
with Ada.Text_IO; use Ada.Text_IO;

procedure Parameter_Example is
   -- GCLOCK with different Max_Count values
   Algo1 : GCLOCK_Algo := Init_GCLOCK(10, 1);  -- Each page gets 1 chance
   Algo2 : GCLOCK_Algo := Init_GCLOCK(10, 3);  -- Each page gets 3 chances
   Algo3 : GCLOCK_Algo := Init_GCLOCK(10, 5);  -- Each page gets 5 chances
   
   Pages : constant array(1..50) of Page_ID := (others => 1);
begin
   for P of Pages loop
      Access_Page(Algo1, P);
      Access_Page(Algo2, P);
      Access_Page(Algo3, P);
   end loop;
   
   Put_Line("Max_Count=1: " & Natural'Image(Get_Page_Faults(Algo1)) & " faults");
   Put_Line("Max_Count=3: " & Natural'Image(Get_Page_Faults(Algo2)) & " faults");
   Put_Line("Max_Count=5: " & Natural'Image(Get_Page_Faults(Algo3)) & " faults");
   
   -- Higher Max_Count typically results in fewer faults
end Parameter_Example;
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make` or `make all` | Build the library (default) |
| `make library` | Build the library only |
| `make tests` | Build and run all 15 tests (24 assertions) |
| `make test` | Build and run simple demonstration |
| `make testlib` | Build test library only |
| `make clean` | Remove build artifacts (obj/, bin/, *.o, *.ali, *.exe) |
| `make clobber` | Full clean (clean + remove executables) |
| `make help` | Show available targets |

## Technical Details

### Implementation Notes

- **Fixed-size arrays**: The algorithms use a maximum capacity of 1000 pages (`Max_Pages` constant in `clock_algorithms.ads`)
- **1-based indexing**: Arrays use 1-based indexing (1..Max_Pages) for compatibility with Ada's discriminated records
- **Capacity tracking**: Each algorithm tracks its actual capacity separately from the array size
- **Ada 2012 features**: Uses tagged types, abstract procedures, and other modern Ada features

### Performance Considerations

- All algorithms have O(1) average time complexity for page access
- The Clock algorithms use O(n) worst-case for scanning, where n is the capacity
- CAR and Clock-Pro have more complex data structures but maintain good performance

### Memory Usage

- Each algorithm uses O(n) memory where n is the capacity
- CAR uses additional memory for its history caches (B1, B2)
- Clock-Pro uses a doubly-linked list for efficient page management

## Contributing

1. **Fork the repository** on GitHub
2. **Create a feature branch** for your changes
3. **Add tests** for new functionality or bug fixes
4. **Ensure all tests pass** before submitting
5. **Submit a pull request** with a clear description

### Adding New Tests

To add a new test:

1. Add a procedure declaration in `tests/clock_tests.ads`
2. Implement the test in `tests/clock_tests.adb`
3. Call the test from `Run_All_Tests`
4. Follow the numbering scheme (e.g., if adding to Test 1, use 1.6, 1.7, etc.)

Example:

```ada
-- In clock_tests.ads
procedure Test_Clock_New_Feature;

-- In clock_tests.adb
procedure Test_Clock_New_Feature is
   Algo : Clock_Algo := Init_Clock(3);
begin
   New_Line;
   Put_Line("  1.6: New feature test");
   
   -- Test code here
   Assert_Equal(Get_Page_Faults(Algo), Expected, "Description");
   
   Passed_Tests := Passed_Tests + 1;
end Test_Clock_New_Feature;

-- In Run_All_Tests, add:
Test_Clock_New_Feature;
```

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by classic operating system textbooks and research papers
- Implemented in **Ada 2012** for type safety, reliability, and maintainability
- Designed for both educational use and practical memory management research

## References

- Silberschatz, Galvin, Gagne - "Operating System Concepts"
- Tanenbaum - "Modern Operating Systems"
- Original Clock algorithm: Corbató, et al. (1960s)
- CAR algorithm: Megiddo and Modha (2003)
- Clock-Pro: Jiang, et al. (2005)

---

**Maintained by:** Robert Boettcher SF  
**Repository:** [github.com/RobertBoettcherSF/Ada-clock-replacement](https://github.com/RobertBoettcherSF/Ada-clock-replacement)
