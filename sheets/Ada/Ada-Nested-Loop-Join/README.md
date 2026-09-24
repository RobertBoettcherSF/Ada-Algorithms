# Ada Nested Loop Join Algorithm

## Project Overview
This codebase implements the **Nested Loop Join** algorithms as described by database architecture theory. It performs relational joins by evaluating matched keys across an Outer Relation and an Inner Relation. The system emphasizes strict type safety, predictable execution boundaries, and algorithmic distinctness natively implemented in Ada 2012.

## Features
- **Naive Nested Loop Join**: Traditional $O(\vert{}R\vert{} \times \vert{}S\vert{})$ nested scans.
- **Block Nested Loop Join**: Emulates memory/IO chunking by iterating through the Outer Relation in restricted block sizes, drastically reducing the required number of full scans on the inner array.
- **Index Nested Loop Join**: Subsumes the inner iteration by pre-computing a hashed memory index (bucket array) representing the Inner Relation, allowing rapid $O(1)$ lookups per Outer record.
- **Strong Typing**: `Key_Type` and `Data_Type` custom bindings prohibit cross-domain assignments natively at compile time.
- **Support for M:N mappings**: Safely handles many-to-many relationship mapping implicitly through sequential payload vectors.

---

## Testing (Verification & Validation)

This software operates under a **Pessimistic Verification & Validation (V&V)** testing mindset. 

Instead of writing tests that prove "the code works", the testing suite operates under the fundamental assumption that **the code is broken, poorly integrated, and fails on edge boundaries**.
A test is considered a **PASS** only when the code aggressively disproves the test's pessimistic assumption.

### What the test categories verify:
- **Functional Correctness**: Assertions evaluate whether 1-to-N relationships drop tuples (Testing that an Outer Tuple finding two Inner Matches results in 2 joined records, not 1 or 3).
- **Error Handling**: Exception catching ensures that physically impossible parameters (e.g., Block_Size $\le 0$) do not silently cause memory exhaustion or CPU hangs, but immediately halt via `Invalid_Block_Size`.
- **Edge Cases**: Validates algorithmic stability when joining empty relations, unbalanced tuples, blocks sizes that far exceed index scopes, or blocks that do not strictly divide evenly across array sizes.
- **Index Integrity**: Confirms that hashed index generation does not cannibalize data when duplicate keys exist in the inner set (hash collisions vs data duplication).

### Why these tests matter:
In critical systems written in Ada, memory bounds, bounds-checking loops, and unhandled exceptions are catastrophic. Validating that algorithms scale dynamically (without constraint errors or garbage memory mapping) guarantees reliability in data-intensive applications. By disproving assumptions of failure, we prove programmatic stability.

---

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. The codebase utilizes a `Makefile` pointing to the provided `.gpr` file.

To compile both the main application and the test suite:
```bash
make all
