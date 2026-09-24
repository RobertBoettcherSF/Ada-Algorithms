# Automatic Train Operation (ATO) in Ada 2023

Project Overview:
This package offers a highly rigorous, strongly-typed implementation of core algorithms for Automatic Train Operation (ATO) modeling Grade of Automation (GoA) levels 1 through 4. It leverages Ada 2023 constructs, explicit domain models, strict subtype constraints, and pre/post-conditions to prevent illegal maneuvers and calculation drift.

Features:
* Automatic Train Protection (ATP): Calculates mathematically safe stopping speed curves using physics and predefined comfort deceleration limits.
* Automatic Train Operation (ATO): Manages intelligent acceleration, braking, and coasting to safely reach destination speed targets.
* Precision Station Stopping: Regulates exact stopping offsets to within centimeters to ensure safe alignments.
* Automatic Door Control: Opens and closes station doors automatically for semi-automated (GoA 2) up to driverless models (GoA 4) without jeopardizing safety.
* Unattended Operations (UTO) Handling: Models extreme anomaly resolution (like sudden obstacles on the track) unique to GoA 4.

Usage:
To compile and view the automated test suites processing simulated physics conditions:
$ make test
This will execute the standalone suite verifying kinematic equations, coasting tolerances, station boundaries, threshold conditions, and exception-driven design-by-contract parameters.

Testing:
This test suite inherently runs functional correctness verifications, error/exception handling, and safety invariants. Every boundary checks pre/post contracts ensuring variables like un-braked kinematics or erroneous inputs (e.g. accelerating a train towards a negative track segment, assigning GoA levels beyond capabilities) are correctly caught by the compiler or the runtime assertions engine before disaster occurs. 

Building:
* Requires the GNAT Ada compiler.
* The Makefile executes using `gnatmake` with `-gnatwa` (all warnings enabled - code operates with zero warnings), `-gnata` (runtime assertions/contracts active), and `-gnat2022` to leverage proper Ada 2023 / 2022 constructs seamlessly.
