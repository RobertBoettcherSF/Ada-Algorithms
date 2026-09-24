Project Overview: 
This project provides a robust, strongly-typed Ada 2023 implementation of a STRIPS-style planning engine, modeled after the foundational concepts of the Planning Domain Definition Language (PDDL). PDDL defines domains through states characterized by positive/negative propositions and actions comprising preconditions and effects. The engine implements core logic resolution via zero-overhead bitwise packed arrays, ensuring immense state-transition performance.

Features:
* Formal Propositional Logic State Engine: Uses discrete packed bit-vectors representing state spaces up to 128 distinct propositions.
* Precondition and Effect Resolution: Fully supports matching and mutating states using positive/negative preconditions and add/delete effects seamlessly.
* Breadth-First Search (BFS): Generates mathematically optimal (shortest path) action sequences from initial state to goal configurations.
* Depth-First Search (DFS): Reaches solutions dynamically traversing the tree iteratively with configurable maximum depth limits to avoid infinite cycles.
* Zero-Warning Compliance: Meets rigorous GNAT standard `-gnatwa` ensuring no unused variables, side-effects, or untyped data risks.
* Robust Edge Case Handling: Protects against invalid actions and trivially unreachable permutations through strongly-typed exceptions (`Invalid_Action`, `No_Plan_Found`).

Usage:
To build and execute the suite (which doubles as the functional example set):
    $ make test

Expected output will trace all 15 tests, printing PASS logs for preconditions validation, search structure capabilities, depth-limited pruning behaviors, and edge-case exceptions, summarizing: `===  45 passed,  0 failed ===`. 

Testing:
Verification leverages exhaustive functional and boundary test categories. Applicability rules (positive/negative overlap) isolate logic faults. Evolution checks ensure strictly deterministic transitions. Pathing tests validate graph shortest-path reliability (BFS) versus resource-constrained pathfinding limits (DFS). 

Building:
Ensure you are using GNAT with Ada 2022/2023 support enabled via `-gnat2022`. Execution targets `tests.adb` as a standalone verified binary managed entirely by `make`.
