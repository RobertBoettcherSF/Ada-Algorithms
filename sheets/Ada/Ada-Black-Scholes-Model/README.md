Project Overview
This project implements the Black-Scholes model, a mathematical model for the dynamics of a financial market containing derivative investment instruments. The package calculates theoretical prices for European call and put options, as well as the five major "Greeks" (Delta, Gamma, Vega, Theta, Rho) which measure sensitivity to various underlying market parameters. It implements the generalized Black-Scholes-Merton extension to support continuous dividend yields.

Features
* Calculates European Call and Put option prices.
* Computes all primary Greeks (Delta, Gamma, Vega, Theta, Rho) for both Call and Put.
* Accounts for dividend yield (generalized Merton model).
* Expiration-aware, correctly evaluating options at exactly zero time-to-maturity (Intrinsic value).
* Gracefully raises dedicated exceptions (`Maturity_Expired`) when sensitivities mathematically tend toward infinity.
* Implements robust type safety using domain-specific types/subtypes avoiding bare floats.

Usage
Run `make test` from your terminal in the directory where the source code is extracted. It will compile the project and execute the comprehensive suite of tests showing detailed output for successful constraints matching.
Example execution outcome:
Running tests...
TEST 1 — Call Option Price
  PASS — 1.1 Call ATM (S=100, K=100)
...

Testing
The `tests.adb` program is both a standalone main executable and a testing suite. It verifies correct integration and exact mathematical boundaries against proven values. Thirteen test suites categorize verifications covering Standard Pricing (ATM/ITM/OTM), continuous dividend impacts, Put-Call parity dynamics, Greek limit evaluation, parameter boundary limits, and zero time-to-maturity edge cases checking limits where options expire. This suite disproves faults in the math approximations (normal distributions) guaranteeing robust behavior.

Building
You require the GNAT compiler configured for Ada 2022/2023. Run `make` to compile cleanly with warnings enabled as errors. No external packages (beyond Standard and Ada.Numerics) are required. Build environment targets GNAT project specifications conforming to ISO/IEC 8652:2023 directives.
