# Truncated Binary Encoding in Ada

## Project Overview
This repository provides a strict, type-safe Ada implementation of the **Truncated Binary Encoding** algorithm. This entropy encoding scheme is primarily used for assigning optimally sized binary codes to uniform probability distributions with an arbitrary alphabet size $n$. Unlike standard binary encoding, this algorithm is mathematically generalized so $n$ does not need to be a strict power of 2. 

## Features
- **Strong Typing Domain Restrictions**: Relies on specific numeric types (`Symbol_Value` and `Alphabet_Size`) to prevent cross-domain compilation errors.
- **Dynamic Encoding**: Converts a numerical symbol into a dynamically truncated $k$ or $(k+1)$ bit string.
- **Stream Decoding Variant (`Decode`)**: Extracts a symbol safely from an ongoing string of bits, passing back exactly how many bits were mathematically consumed. 
- **Exact Decoding Variant (`Decode_Exact`)**: Strict validation that accepts a string, decodes it, and asserts that absolutely zero garbage/trailing bits are left unread.
- **Constant Time Space Calculations**: No recursive loops for space reservations.

## Testing
This project embraces a strict Verification and Validation (V&V) philosophy typical in critical systems engineering.

Our tests operate under the initial assumption that **the codebase is broken, non-functional, or highly insecure**. A test result of `PASS` explicitly means the assumption has been disproved and the program mathematically fulfills the requirement.

### What We Verify (The 4 Categories)
1. **Functional Correctness:** Verifies algorithmic integrity (Are $k$ bounds mapping correctly? Does $N$ shift correctly when $X \ge U$?)
2. **Edge Cases:** Verifies limits in algorithmic topology (Testing $N=1$ where 0 bits are required, or where $N=2^y$ disabling truncations).
3. **Error Handling:** Verifies deterministic abort routines. Ensures bad data raises strictly controlled exceptions (`Invalid_Symbol_Error`, `Decoding_Error`) rather than causing memory leaks or unpredictable buffer overruns.
4. **Data Validation:** Prevents data pollution natively utilizing Ada’s robust compile-time constraints (e.g., $N=0$ correctly triggering `Constraint_Error`).

### Why These Tests Matter
In uniform probability compression standards (such as transmitting video/telemetry frames), an off-by-one bit error shifts all subsequent data, destroying the stream. These tests ensure absolute reliability by guaranteeing the decoder and encoder stay perfectly symmetric, maintaining safety constraints even when fed malformed noise over untrusted networks.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. Compile the project via the provided Makefile:
```bash
make all
