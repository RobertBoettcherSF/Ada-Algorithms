# Abstract Interpretation in Ada

Project Overview:
This project implements core algorithms and data structures for Abstract Interpretation, a theory of sound approximation of the semantics of computer programs. It models variable states undergoing execution transitions by evaluating operations over simplified domains instead of concrete values. The implementation covers two standard abstract domains representing properties of integer variables: the Sign Domain (tracking if numbers are Negative, Zero, or Positive) and the Interval Domain (tracking minimum and maximum bounds, including infinities).

Features:
* Sign Domain Analysis: Complete powerset lattice for integer signs {-, 0, +} supporting state transition operations like Join, Meet, Abstract Addition, and Abstract Multiplication.
* Interval Domain Analysis: Rigid lower and upper bound tracking [Lower, Upper] mapping domains dynamically.
* Infinity Support: Computations support both Finite integer bounds and Infinite constraints (+Inf, -Inf).
* Loop Invariant Convergence: Employs standard Widening operations for the interval domain to force termination over iteratively expanding bounds.
* High Reliability: Strongly typed Ada 2023 design enforcing correctness through robust preconditions and contract aspects (Global, Pre, Post).

Usage:
To build and execute the system, simply run `make test` from your terminal. 
Expected output will display execution verification traces running 15 comprehensive tests covering various abstract interpretation behaviors. Upon successful validation, the suite prints a final tally of passed assertions and gracefully exits.

Testing:
The self-contained test suite (`tests.adb`) doubles as the execution main point. It rigorously exercises mathematical correctness and computational integrity across all domains.
* Functional Correctness tests validate Cartesian product computations of signs and interval ranges during additions and multiplications. 
* Edge Cases assure stability when computing bounds intertwined with Positive/Negative Infinities and Zero scaling. 
* Error Handling validates safe exception bubbling when semantic rules (e.g., Lower Bound > Upper Bound) are intrinsically violated. 
* Invariant tests guarantee convergence features, proving loop Widening accurately maps expanding bounds to Infinity.

Building:
Prerequisites: A modern GNAT toolchain capable of handling Ada 2022/2023 constructs. 
The system is built leveraging standard features from ISO/IEC 8652:2023. You can invoke the included Makefile using `make all` to build the standalone binary, or `make clean` to remove compiled object artifacts.
