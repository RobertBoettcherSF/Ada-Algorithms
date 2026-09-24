# Ada Buddy Memory Allocation

## Project Overview
This repository provides a robust, strictly-typed Ada implementation of the **Buddy Memory Allocation** algorithm. Buddy allocation is a memory management technique that divides memory into partitions to try to satisfy a memory request as suitably as possible. 

Unlike standard dynamic allocators that suffer from external fragmentation, the Buddy system recursively halves memory blocks and subsequently merges "buddies" (sibling blocks) back together when they are freed. This implementation avoids internal dynamic allocation entirely by using a static, array-backed binary tree to track metadata, making it suitable for deterministic or embedded environments.

## Features and Variants
This package implements three distinct variants of the Buddy system:

1. **Binary Buddy System (Standard)**
   - Memory is divided into powers of 2 ($2^k$).
   - *Pros:* Extremely fast bitwise offset calculations.
   - *Cons:* Can suffer from internal fragmentation if requested sizes don't align well with powers of 2.
2. **Fibonacci Buddy System**
   - Memory sizes follow the Fibonacci sequence. A block of size $F_n$ splits into $F_{n-1}$ and $F_{n-2}$.
   - *Pros:* Tighter memory bounds than Binary, reducing internal fragmentation.
3. **Weighted Buddy System**
   - Allows block sizes of $2^k$ and $3 \times 2^k$. A block of $3 \times 2^k$ splits into $2^{k+1}$ and $2^k$.
   - *Pros:* Offers a compromise between the simplicity of Binary and the tighter fitting of Fibonacci.

## Repository Structure
```text
.
├── src/
│   ├── buddy_allocators.ads   # Package specification and types
│   ├── buddy_allocators.adb   # Implementation of allocation/merging logic
│   └── main.adb               # Example demo application
├── tests.adb                  # Comprehensive validation test suite
├── Makefile                   # Build automation
├── buddy.gpr                  # GNAT project file
└── README.md                  # Project documentation
