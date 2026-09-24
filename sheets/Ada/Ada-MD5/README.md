# Ada 2023 MD5 Implementation

## Project Overview
This project is an expert-grade, standalone Ada 2023 implementation of the Message-Digest Algorithm 5 (MD5). Derived closely from the specifications provided in its widely adopted standards and utilizing strict software engineering practices, it produces robust hashes for inputs ranging from byte arrays to dynamically streamed strings. It handles all necessary 64-byte block alignments and edge-case padding inherently required by the 128-bit MD5 signature.

## Features
* Strong Typing: Strict domain usage of bytes and 32-bit words explicitly preventing unexpected runtime cast behavior.
* Variant Complete: Supports one-shot String inputs, one-shot Byte Array inputs, and streaming Incremental context inputs.
* Context State Encapsulation: Object-oriented contexts rigorously enforce states preventing modifications outside of an initialized context pipeline. 
* Fully Contracted: Subprograms utilize detailed Ada Pre, Post, and Global aspects clarifying state logic and enforcing algorithmic correctness boundaries.
* Warning-Free: Tested aggressively under `-gnatwa` for spotless integration into larger GNAT frameworks.

## Usage
Run `make test` from your terminal inside the project directory. The Makefile triggers compilation seamlessly, building the binary natively into `/bin/tests`. No intermediate linking errors apply. Expect a direct read-out verifying 39 specific assertions passing cleanly. Output yields verification tags matched against exact RFC vectors and boundary thresholds.

## Testing
The embedded test suite (`tests.adb`) exhaustively verifies validation categories to disprove defects continuously:
* Functional Correctness: Evaluated through primary vectors outlined in RFC 1321 ensuring pure 1-to-1 byte parity.
* Edge Cases: Boundary size limits triggering 55, 56, 63, and 64 byte blocks forcefully execute all branching padding outcomes proving block carryovers trigger flawlessly.
* Incremental Invariance: Split payloads evaluated logically against holistic equivalents for streaming consistency.
* Error Handling: State-mutating errors (e.g., calling Update on closed context streams) assert strict `MD5_Error` responses instead of undefined bounds overwrites. 

## Building
1. Prerequisites: Ensure GNAT toolchain (or equivalent Ada 2022/2023 compatible compiler) is installed.
2. Run standard target: `make test` utilizes GNAT project settings adhering strictly to `-gnat2022` enabling native ISO/IEC 8652:2023 support.
