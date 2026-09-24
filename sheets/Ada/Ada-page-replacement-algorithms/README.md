# Ada Page Replacement Algorithms

## Overview

This is an Ada implementation of various **page replacement algorithms** used in operating systems for virtual memory management. When a process accesses a page that is not in physical memory (a **page fault**), the OS must decide which page to evict to make room for the new page. This project simulates and compares different strategies for making that decision.

## Page Replacement Algorithms Implemented

| Algorithm | Description |
|-----------|-------------|
| **FIFO** (First-In-First-Out) | Replaces the page that has been in memory the longest |
| **LRU** (Least Recently Used) | Replaces the page that hasn't been accessed for the longest time |
| **Random** | Replaces a randomly selected page |
| Clock | Uses a circular list with reference bits (not fully implemented) |
| Optimal | Replaces the page that won't be used for the longest time in the future (theoretical) |
| NRU (Not Recently Used) | Uses reference and modified bits to select victims |

## Project Structure

```
Ada-page-replacement-algorithms/
├── page_replacement.ads      # Package specification (types and declarations)
├── page_replacement.adb      # Package body (algorithm implementations)
├── test_page_replacement.adb # Test program
├── page_replacement.gpr      # GNAT Project file
├── Makefile                  # Build configuration
├── README.md                 # This file
├── obj/                      # Object files directory
└── bin/                      # Executable directory
```

## Prerequisites

- **GNAT Ada Compiler** (part of GCC)
- **GPRBuild** (GNAT Programming Studio build tool)

### Installation on Ubuntu/Debian

```bash
sudo apt-get install gnat gprbuild
```

### Installation on macOS (using Homebrew)

```bash
brew install gnat
```

## Building and Running

### Using Make

The easiest way to build and run the project:

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-page-replacement-algorithms.git
cd Ada-page-replacement-algorithms

# Build and run
make run
```

### Manual Build

Alternatively, you can build and run manually:

```bash
# Build using gnatmake with the project file
gnatmake -P page_replacement.gpr

# Run the executable
./bin/test_page_replacement
```

### Clean Build

```bash
make clean    # Remove object files and executable
make rebuild  # Clean and rebuild
```

## Understanding the Output

When you run the program, you'll see output like:

```
=================================================
  Page Replacement Algorithm Simulation
=================================================

Reference String: 
   1  2  3  4  1  2  5  1  2  3 
Number of Frames:  3

-------------------------------------------------
Algorithm        | Page Faults | Replacements
-------------------------------------------------
FIFO            |  10         |  7
LRU             |  10         |  7
Random          |  10         |  7
-------------------------------------------------
```

### What the Numbers Mean

- **Reference String**: The sequence of pages that the process accesses
- **Number of Frames**: How many pages can fit in physical memory at once
- **Page Faults**: How many times a page was not in memory and had to be loaded
- **Replacements**: How many times an existing page had to be evicted to make room

### Important Notes

The current implementation has some known issues:

1. **Page Fault Counting**: All page references are currently counted as faults (incorrect)
2. **LRU Implementation**: Currently uses FIFO logic instead of proper LRU tracking
3. **Algorithm Comparison**: With the current reference string and 3 frames, all algorithms show identical results

These issues are documented in the code comments and should be addressed in future updates.

## Customizing the Simulation

To test with different parameters, modify `test_page_replacement.adb`:

1. **Change the reference string**: Edit the `The_References` constant
2. **Change the number of frames**: Edit the `Num_Frames` variable
3. **Test different algorithms**: Add calls to `Simulate` with other algorithm types

Example reference strings to try:

```ada
-- Simple sequential access
(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

-- Locality of reference (common pattern)
(1, 2, 3, 1, 2, 3, 4, 5, 4, 5, 6, 7, 6, 7, 8, 9)

-- Worst case for FIFO
(1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4)
```

## Code Organization

### page_replacement.ads

The **specification file** defines:
- Page and frame number types
- Page state types (reference bit, modified bit)
- Page table entry structure
- Algorithm type enumeration
- Statistics record
- Procedure and function declarations

### page_replacement.adb

The **implementation file** contains:
- `Initialize`: Sets up the page table
- `Is_In_Memory`: Checks if a page is loaded
- `Find_Frame`: Locates where a page is loaded
- `Find_Free_Frame`: Finds an empty frame
- `Find_FIFO_Victim`: FIFO algorithm implementation
- `Find_LRU_Victim`: LRU algorithm implementation
- `Find_Random_Victim`: Random algorithm implementation
- `Algorithm_Name`: Returns algorithm name as string
- `Simulate`: Main simulation procedure

### test_page_replacement.adb

The **test program** that:
- Defines the reference string
- Sets the number of frames
- Runs simulations for each algorithm
- Displays formatted results

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Areas for Improvement

- Fix the page fault counting logic
- Implement proper LRU tracking (update Last_Used on every access)
- Implement Clock, Optimal, and NRU algorithms
- Add more test cases
- Add command-line parameter support
- Add visualization of page table state during simulation

## License

This project is open source. See the [LICENSE](LICENSE) file for details.

## References

- Operating System Concepts by Silberschatz, Galvin, and Gagne
- Modern Operating Systems by Tanenbaum
- [Ada Programming Language](https://www.adaic.org/)

---

**Author**: Robert Boettcher  
**Language**: Ada  
**Status**: Educational / Work in Progress
