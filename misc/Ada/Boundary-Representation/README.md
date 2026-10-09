# Boundary Representation (B-Rep) in Ada 2023

## Project Overview
This project is an Ada 2023 implementation of Boundary Representation (B-Rep), a computational model used in solid modeling to represent 3D shapes via topological elements (vertices, edges, faces). The implementation emphasizes topological integrity using the Euler-Poincaré characteristic and provides specialized Euler operators (such as MVFS, MEV, MEF, KEV, and KEF) that allow constructing and modifying solid objects and checks whether a model is a closed manifold solid.

## Features
- **Strict Topological Definitions:** Custom types and records for Points, Vertices, Edges, and Faces.
- **Closed-solid check:** `Check_Solid` reports whether the model is a closed orientable 2-manifold surface: every face has a closed loop of active vertices and edges, every edge lies on exactly two faces that traverse it in opposite directions, and the faces around every vertex form one ring. It then counts the shells (faces connected through shared edges) and gives each shell's genus from `V - E + F = 2 - 2g`. `Is_Valid_Manifold` is `Check_Solid (Model).Failure = None`; any genus and any number of shells are allowed. `Euler_Poincare_Characteristic` alone is only a count: `V - E + F = 2` is neither necessary (a torus gives 0, two cubes give 4) nor sufficient (a reversed face or a dangling edge can still give 2).
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
You will see 16 sequentially numbered tests executing over 65 assertions, ending with a final count of tests passed, e.g.:
  PASS -- 1.1 Vertices is 0
  ...
===  65 passed,  0 failed ===

## Testing
The embedded test suite (`tests.adb`) achieves verification and validation across several categories:
1. **Functional Correctness:** Verifies basic geometric assignment (`Get_Vertex_Point`, `Are_Connected`).
2. **Topological Invariants:** Evaluates whether Euler operations maintain a valid mathematical shell property after arbitrary mutations.
3. **Edge Cases:** Simulates zero-length array inputs for topological shells and prevents cascading allocations.
4. **Error Handling:** Validates capacity bounds (handling faces with too many edges) and graceful rejection of non-existent invalid IDs via proper exception routing.

## Building
- **Prerequisites:** GNAT compiler supporting Ada 2022/2023 capabilities. GNU Make.
- Build standard targets using `make all` or `make clean`.

## Model change (2026-10-09)
Faces now record an oriented vertex loop, which the closed-solid check needs. `Make_Face` derives it from the edges in the order given, when they form one closed loop through distinct vertices (at least 3 edges); a new `Make_Polygon_Face` builds a face from a vertex loop and reuses or creates the edges between consecutive vertices. Faces without such a loop (the skeletal faces made by `Make_Vertex_Face_Shell` and `Make_Edge_Face`, open chains) make `Is_Valid_Manifold` False. The Euler operators keep `V - E + F` unchanged; they do not build face loops, so a model made only with them is not a closed solid. Before this change `Is_Valid_Manifold` returned `V - E + F = 2`.
