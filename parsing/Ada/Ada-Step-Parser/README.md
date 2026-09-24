Project Overview
This project provides a robust, strongly-typed lexical analyzer and parser for the ISO 10303-21 (STEP-file) clear text encoding standard. It handles the structural tokenization and syntax validation of STEP physical files, interpreting various encoding elements (integers, reals, strings, entity references, enumerations) and properly breaking them down by their logical section hierarchies. The implementation complies with Ada 2023 constructs, guaranteeing type safety and contract adherence.

Features
* Lexical Analyzer: Recognizes STEP-specific tokens such as `#123` (Entity Refs) and `.T.` (Enums).
* Edition 1 & 2 Support: Implements parsers for standard `HEADER` and `DATA` sections.
* Edition 3 Support: Adds variants for `ANCHOR`, `REFERENCE`, and `SIGNATURE` sections.
* Error Handling: Robust catching of unbalanced parentheses, unterminated strings, and invalid schema wrappers.
* Contract-Based Design: Verifies precondition initialization constraints and state correctness on parse iterations.

Usage
Run `make test` from the terminal. The framework will invoke GNAT to compile the specification, body, and test suite. The `tests` binary will automatically execute, and you will see output validating every tokenizer state and parsed variant sequence with PASS/FAIL notifications.

Testing
The suite runs 13 automated tests covering 39 distinct assertions. Categories include functional validation (full valid exchange structures), lexer verification (identifiers, keywords, strings, whitespace, floats), structural variant checks (Header vs Anchor logic), and failure tolerance (unmatched tokens and missing file signatures). This ensures both verification (did we build it right?) and validation (does it match the ISO schema rules?).

Building
Requires the GNAT compiler with Ada 2022/2023 capabilities. Ensure your environment path resolves `gnatmake`. Run `make all` to generate the binaries in the `bin/` directory without warnings (-gnatwa).
