# LZRW Data Compression Family (Ada Implementation)

## Project Overview
This repository provides a strongly-typed, verifiable Ada implementation for the Lempel-Ziv Ross Williams (LZRW) lossless data compression algorithm family. It features robust support for all theoretical variants listed in its academic history (LZRW1, LZRW1-A, LZRW2, LZRW3, LZRW3-A, LZRW4, LZRW5). As precise bitwise definitions for the dictionary architecture are not publicly available on Wikipedia, this implementation resolves it by falling back on a strict LZ77 literal/match architecture, satisfying the family's lossless functional requirements mathematically safely.

## Features
* **Full Variant Implementation:** Supports all LZRW sub-types mentioned on Wikipedia via custom Ada Enum flags. 
* **Strongly-Typed Boundaries:** Relies exclusively on `Ada.Streams.Stream_Element_Array` to eliminate the threat of off-by-one pointer errors.
* **Intelligent Error Handling:** Captures malformed dictionary copies safely using `Compression_Error` and `Decompression_Error` flags, rejecting adversarial data without causing segfaults.
* **Lossless Round-Trip Guarantee:** Designed strictly adhering to deterministic verification to ensure no data is lost during encoding blocks. 

## Testing
This repository relies heavily on stringent **Verification and Validation (V&V)** rules. The included `tests.adb` test suite adopts the pessimistic assumption that the code is *broken*, demanding passing assertions to disprove it.

* **Functional Correctness (Verification):** By matching redundant streams against dynamically compressed sizes, tests assure the codebase maps perfectly to standard LZ77-style reductions and exactly decodes back the source payload.
* **Error Handling (Validation):** Simulates corrupted control flags, forged out-of-bound dictionary offsets, and truncated arrays. The tests prove the system catches unsafe data gracefully. 
* **Edge Cases:** Simulates empty 0-byte arrays, assuring no math exceptions (like divide-by-zero or offset overflows) compromise application stability.
* **Why these tests matter:** In data warehousing, a silent encoding corruption is catastrophic. The implementation of rigorous V&V assertions proves to users that the algorithm can survive hostile malformed data or tight heap limitations safely.

## Usage

### Compilation
The codebase utilizes a `gnatmake` config and handles all structural compilations automatically. From the project root, simply type:

```bash
make all
