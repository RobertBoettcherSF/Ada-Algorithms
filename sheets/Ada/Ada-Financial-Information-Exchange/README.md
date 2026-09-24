Project Overview: This project implements a fully featured parser, generator, and validator for the Financial Information eXchange (FIX) protocol in strictly typed Ada 2023 (ISO/IEC 8652:2023). It securely encodes domain concepts using custom subtyping and pre/post condition contracts. Variants cover standard implementations including generic Heartbeats, New Order Singles for trade initiation, and Execution Reports to handle order lifecycle events.

Features: 
* Fully compliant serialization and Tag=Value deserialization with SOH control byte support.
* Dynamic Checksum calculation and message validity assertions.
* Specialized variant generators: Create_Heartbeat, Create_New_Order_Single, Create_Execution_Report.
* Strict validation via custom exceptions: Field_Not_Found, Malformed_Message, Invalid_Checksum.
* Memory-safe and side-effect free design using zero dynamic allocations for internal fields.

Usage: 
Compile the project and run the standalone verification suite:
$ make test
The suite outputs line-by-line validation, reporting passes for checksum logic, sequence formatting, field overwrites, and expected parsing boundaries. Example output:
  PASS — 1.1 Has_Field confirms presence of Tag 35
  PASS — 1.2 Get_Field retrieves correct value...
  ===  39 passed,  0 failed ===

Testing: Contains 13 robust categorical tests spanning standard creation logic, serialization length checking, body manipulation, exception raising for missing or malformed variables, and protocol-specific message variants. This exhaustive coverage verifies both functional pathways and hostile edge case scenarios to guarantee memory safety and data validation.

Building: Requires GNAT with Ada 2022/2023 language switches. GPR configuration specifies `-gnat2022` and enforces full warning eradication using `-gnatwa`. Run `make` to compile cleanly into the `bin/` directory without any placeholder outputs.
