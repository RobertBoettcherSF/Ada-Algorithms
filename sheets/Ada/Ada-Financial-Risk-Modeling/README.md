Project Overview
This Ada project implements core market risk algorithms used in Financial Risk Modeling. It provides tools to quantify the risk of a portfolio over a specific time frame, covering the two most prevalent regulatory and trading metrics: Value at Risk (VaR) and Expected Shortfall (ES, also known as Conditional VaR). The models compute these statistics based on arrays of historical returns using strict strong typing and mathematical rigor.

Features
* Historical Simulation Value at Risk (VaR): Sorts empirical returns and finds the exact quantile bound (with interpolation support) for a given confidence level.
* Historical Expected Shortfall (ES): Averages all empirical returns that exceed the VaR threshold.
* Parametric (Variance-Covariance) VaR: Computes VaR analytically assuming a normal distribution, relying on computed mean and standard deviation.
* Parametric Expected Shortfall (ES): Evaluates the expected tail loss theoretically using probability density and inverse CDF rational approximations.
* Type safety via custom `Rate` and `Confidence_Level` subtyping.
* Pre and Post condition contracts enforcing valid states natively.

Usage
Run `make test` to build and execute the `tests.adb` program. 
The expected output is a readout of the 13 test suites executing 39 total assertions verifying calculation boundaries, exact mathematical expectations, and expected exceptions. The final line will display `===  39 passed,  0 failed ===`.

Testing
The test suite doubles as the primary executable and API demonstration (`tests.adb`). Coverage spans:
* Functional Correctness: Normal distribution approximations and exact quantile verification against pre-computed textbook outputs.
* Edge Cases: Arrays with identical elements, extreme (99.99%) confidence levels, and single-element inputs safely degrading gracefully.
* Error Handling: Expected failures on algorithms requesting standard deviation over a single element are captured and validated via `Insufficient_Data` exceptions. 
* These strict testing categorizations guarantee mathematical and structural robustness required for validation in strict regulatory systems.

Building
Prerequisites: A GNAT compiler supporting Ada 2022 (ISO/IEC 8652:2023).
Use the provided `Makefile` which specifies `-gnatwa` (all warnings) and `-gnat2022` to ensure rigorous compilation purity. Execute `make all` to build, or `make clean` to erase build artifacts.
