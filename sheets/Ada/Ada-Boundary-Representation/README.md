# Boundary Representation (B-Rep) in Ada 2023

## Project Overview
This project is an Ada 2023 implementation of Boundary Representation (B-Rep), a computational model used in solid modeling to represent 3D shapes via topological elements (vertices, edges, faces). The implementation emphasizes topological integrity using the Euler-Poincaré characteristic and provides specialized Euler operators (such as MVFS, MEV, MEF, KEV, and KEF) that allow constructing and modifying solid objects while guaranteeing mathematically closed manifolds.

## Features
- **Strict Topological Definitions:** Custom types and records for Points, Vertices, Edges, and Faces.
- **Euler-Poincaré Validation:** Includes checks to ensure `Vertices - Edges + Faces = 2` for simple closed objects, allowing automatic manifold validation.
- **Euler Operators:**
  - `Make_Vertex_Face_Shell` (MVFS): Spawns an initial point-solid.
  - `Make_Edge_Vertex` (MEV): Extends geometry by creating a new edge ending in a new vertex.
  - `Make_Edge_Face` (MEF): Closes topological loops by bounding a new face with an edge.
  - `Kill_Edge_Vertex` (KEV) & `Kill_Edge_Face` (KEF): Robust reverse deletion operators.
- **Contract-Based Safety:** `Pre`, `Post`, and `Global` aspects heavily leveraged to statically document invariants and runtime bounds.

## Usage
To execute the demonstration and verify the API:

make test

Expected Output:
You will see 13 sequentially numbered tests executing over 39 assertions, ending with a final count of tests passed, e.g.:
  PASS -- 1.1 Vertices is 0
  ...
===  39 passed,  0 failed ===

## Testing
The embedded test suite (`tests.adb`) achieves verification and validation across several categories:
1. **Functional Correctness:** Verifies basic geometric assignment (`Get_Vertex_Point`, `Are_Connected`).
2. **Topological Invariants:** Evaluates whether Euler operations maintain a valid mathematical shell property after arbitrary mutations.
3. **Edge Cases:** Simulates zero-length array inputs for topological shells and prevents cascading allocations.
4. **Error Handling:** Validates capacity bounds (handling faces with too many edges) and graceful rejection of non-existent invalid IDs via proper exception routing.

## Building
- **Prerequisites:** GNAT compiler supporting Ada 2022/2023 capabilities. GNU Make.
- Build standard targets using `make all` or `make clean`.
