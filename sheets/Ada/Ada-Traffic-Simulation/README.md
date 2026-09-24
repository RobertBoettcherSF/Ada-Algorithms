Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation of three fundamental paradigms in traffic simulation: Macroscopic, Microscopic, and Mesoscopic models. Derived from the theoretical frameworks detailed on Wikipedia, the library applies physical modeling at multiple scales. The macroscopic module leverages the Greenshields kinematic wave model to derive flow and speed from overall density. The microscopic module uses a kinematic intelligent-braking/car-following model to advance individual vehicle states based on driver behavior parameters. The mesoscopic model utilizes platoons with transition states and queueing servers driven by link capacities to evaluate traffic on an intermediate scale.

Features
* Microscopic Engine: Deterministic car-following kinematics handling safe headways, minimum gaps, and max acceleration boundaries.
* Macroscopic Engine: Fundamental diagram solver utilizing Greenshields model mapping jam density and free-flow speed to instantaneous volume.
* Mesoscopic Engine: Platoon-based propagation managing node arrivals and rate-limited discrete discharge queues.
* Safety and Correctness: Completely implemented with custom numeric types for distances, speeds, density, and flow ensuring zero dimensional mix-ups.
* Contract-Based Programming: Fully utilizes Ada 2022/2023 Pre/Post conditions ensuring safe parameters across all time-steps.

Usage
Compile and run the test harness via the included Makefile:
  make test
Expected output evaluates all 13 integrated tests spanning the various engine features and states. The binary will assert `0 failed` indicating mathematical correctness.

Testing
The suite includes exactly 13 tests with 3 checks each, covering functional logic, algorithmic correctness, and safety:
* Microscopic states: Acceleration profiles, slowing for preceding cars, hard braking envelopes, and raising `Collision_Error` on unsafe gaps.
* Macroscopic states: Demonstrating free-flow (zero density), peak capacity equations, and hard jam bounds.
* Mesoscopic states: End-to-end verification of state machines moving platoons, arriving them at queues, and discharging fractional volumes correctly via capacity constraints.

Building
* Prerequisites: GNAT (GNAT community or FSF GCC Ada) and `make`.
* Standard compliance: Utilizes the `gnat2022` flag to enforce Ada 2022/2023 rules and executes with zero warnings under `gnatwa`.
