# Automated Theorem Proving (Propositional Logic)

Project Overview:
This project provides a robust, strongly-typed Ada 2022 implementation of foundational algorithms used in Automated Theorem Proving (ATP) and Satisfiability (SAT). Inspired by standard logic solvers, it operates on clauses modeled in Conjunctive Normal Form (CNF) to evaluate propositional formulas through various classical deductive paradigms.

Features:
* Strong Typing: Prevents malformed logic statements natively using Ada's type system (e.g., Variable IDs are bounded to positive ranges, Polarities are explicit enums, preventing the classic DIMACS '0' bug).
* Exhaustive Truth Table Variant: Iterates through binary assignments to explicitly prove validity or evaluate satisfiability across all states.
* DPLL (Davis-Putnam-Logemann-Loveland) Variant: Efficiently evaluates CNF using pure literal elimination, unit propagation, and deterministic branching without mutating the initial context.
* DP Resolution Variant: Validates by systematically eliminating variables via generated resolvents to prove contradictions without recursion.
* Zero Warnings: Compiled and verified strictly against -gnatwa.

Usage:
To build and execute the system's test suite, ensure you have GNAT installed and run:
`make test`
The expected output will print out a sequential checklist of over 39 assertions split across 13 distinct unit test categories. All tests must report 'PASS'.

Testing:
The self-contained `tests.adb` program inherently doubles as the API's usage documentation. It asserts correctness over three major functional spheres:
* Base Logic Validation: Ensures all solvers gracefully evaluate and terminate on empty sets, empty clauses, and standalone unit clauses.
* Procedural Correctness: Checks pure literal logic, truth propagation cascades, and tautological omission logic dynamically over complex multi-variable SAT and UNSAT CNFs.
* Edge-Case Resilience: Validates solver memory boundary safety on variables spanning wide numerical gaps (e.g. IDs 10 to 1000) and duplicate reduction safely within identical logic sets.

Building:
Prerequisites: A compiler compatible with Ada 2022 (ISO/IEC 8652:2023), such as FSF GNAT or GNAT Pro. No external libraries are necessary beyond the standard Ada.Containers package.
