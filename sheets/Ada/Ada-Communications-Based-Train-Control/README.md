# CBTC (Communications-Based Train Control)

Project Overview:
This project implements the core safety and control algorithms of a Communications-Based Train Control (CBTC) system in Ada 2023. It models real-time train localization, continuous distance calculation, and safety thresholds to allow modern railway and transit systems to run at maximum capacity safely. The algorithm manages the distinctions between traditional Fixed Block systems (where track is divided into rigid occupancy zones) and modern Moving Block systems (where movement authorities are dynamically computed based on precise leading-train telemetry).

Features:
* **Moving Block Authority:** Calculates dynamic movement authority limits based on the leader's exact tail position minus a configurable safety margin.
* **Fixed Block Authority:** Calculates discrete authority limits based on track block IDs and predefined block lengths.
* **Automatic Train Protection (ATP):** Continually enforces speed limits and movement authority, factoring in required emergency braking curves to prevent collisions.
* **Automatic Train Operation (ATO):** Determines the optimal acceleration or service braking command based on distance-to-limit, current speed, and target speed.
* **Automatic Train Supervision (ATS):** Validates high-level dispatch instructions such as safe minimum headway departures.

Usage:
Run the standalone test suite by executing `make test` in the repository root.
Expected output is a sequential log of passed test conditions demonstrating standard operation and successful collision/exception mitigation, terminating with a summary like "=== 42 passed,  0 failed ===".

Testing:
The provided `tests.adb` test suite serves a dual purpose as both the verification mechanism and the integration example. It includes functional correctness testing for normal kinematic scenarios (e.g., proper braking distance formulation), edge case handling (stationary trains, high speeds, zero safety margins), and error handling validation (enforcing bounds on colliding blocks). These categories are vital for verifying safety-critical systems, ensuring all variants strictly adhere to ISO/IEC 8652:2023 Ada contracts and type invariants.

Building:
Prerequisites: A modern GNAT toolchain supporting Ada 2022/2023 specifications (e.g., GCC 12+ or GNAT Community). 
Command: Execute `make all` to build the binary in the `bin` directory, or use `make test` to build and run the test suite. The `-gnatwa` flag is enforced to assure 0 warnings.
