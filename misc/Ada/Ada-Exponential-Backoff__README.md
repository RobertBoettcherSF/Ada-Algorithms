# Ada Exponential Backoff

A complete Ada implementation of the **Exponential Backoff** algorithm and its variants, as described in the [Wikipedia article](https://en.wikipedia.org/wiki/Exponential_backoff). This package provides strongly typed, modular, and well-documented procedures for all major variants of the algorithm, including deterministic, randomized, truncated, binary, adaptive, and expected backoff.

---

## 🚀 Quick Start

To compile and run the tests:
```bash
make test
```

To use the library in your own Ada program:
```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure My_Program is
   Config : Backoff_Config := Default_BEB_Config;
   Delay : Delay_Type := Binary_Exponential_Backoff(3);
begin
   -- Use Delay for retry logic
   null;
end My_Program;
```

---

## 📌 Project Overview

This project implements the **Exponential Backoff** algorithm, a closed-loop control system that reduces the rate of a process in response to adverse events (e.g., network collisions, failed connections, or rate-limiting requests). The algorithm is widely used in:

- **Wireless and computer networks** (e.g., Ethernet CSMA/CD, Wi-Fi CSMA/CA)
- **Rate limiting** (e.g., web services, APIs)
- **Retry mechanisms** (e.g., failed connections, timeouts)
- **Collision avoidance** (e.g., multiple senders on a shared channel)

The core idea is to **multiplicatively decrease the rate** of retries after each adverse event, typically using a formula like:

- **Time delay**: `t = b^c * initial_delay`
- **Frequency**: `f = 1 / b^c`

where:
- `b` = base (multiplicative factor, e.g., 2 for binary exponential backoff)
- `c` = number of adverse events (collisions/retries)

---

## ✨ Features

### Implemented Variants

| Variant | Description | Use Case |
|---------|-------------|----------|
| **Deterministic Exponential Backoff** | Fixed delay `t = b^c * initial_delay` | Rate limiting, simple retry mechanisms |
| **Randomized Exponential Backoff** | Random delay in `[0, b^c - 1] * slot_time` | Collision avoidance (e.g., Ethernet) |
| **Truncated Exponential Backoff** | Caps `c` at a maximum retry limit | Prevents excessively long delays |
| **Binary Exponential Backoff (BEB)** | Special case with `b = 2` | Ethernet (IEEE 802.3), Wi-Fi |
| **Adaptive Backoff (Heuristic RCP)** | `K(m)` increases with collisions (e.g., 1, 10, 100, 200, ...) | Lam's algorithm for slotted ALOHA |
| **Expected Backoff** | Computes the expected delay for randomized backoff | Performance analysis |
| **Recovery Mechanism** | Resets collision count after cooling-off period | Dynamic rate adjustment |

### Key Features

- **Strong typing**: Custom types for `Base_Type`, `Max_Retries_Type`, `Delay_Type`, and `Collision_Count_Type`.
- **Modular design**: Separate procedures for each variant.
- **Error handling**: Exceptions for invalid inputs (e.g., `Invalid_Base`, `Retry_Limit_Exceeded`).
- **Helper functions**: `Compute_Power`, `Random_Delay`, `Validate_Config`.
- **Configurable**: Default and custom configurations for all variants.
- **Tested**: 13+ comprehensive tests covering edge cases, invalid inputs, and consistency.

---

## 🧪 Testing

### Test Philosophy

The test suite assumes the code is **broken** and aims to **disprove this assumption**. Tests **PASS** when they show the code behaves correctly. This pessimistic approach ensures robustness by:

- **Verification (V)**: Confirming the code matches the algorithm's mathematical specifications.
- **Validation (V)**: Ensuring the code meets its intended use in real-world scenarios (e.g., network protocols).

### Test Categories

| Category | Tests | Purpose | Why It Matters |
|----------|-------|---------|----------------|
| **Functional Correctness** | 1-7 | Verify each variant implements the algorithm correctly | Ensures mathematical accuracy and adherence to specifications |
| **Edge Cases** | 2, 8, 11 | Test boundary conditions (e.g., `Collision_Count = 0`, `Max_Retries`) | Prevents crashes or incorrect behavior at limits |
| **Error Handling** | 10 | Validate exceptions for invalid inputs (e.g., `Base < 2`) | Ensures safety and predictability |
| **Consistency** | 12 | Check that variants produce expected results relative to each other | Guarantees internal coherence |
| **Performance** | 13 | Test scalability (e.g., large exponents, high collision counts) | Ensures the code handles real-world loads |

### Test Count

- **13 tests** (baker's dozen) with **39 assertions** covering all variants and edge cases.
- Each test includes **2-3 assertions** to verify multiple aspects of the functionality.

### Running Tests

To compile and run the test suite:

```bash
make test
```

**Output**: Each test prints `PASS` or `FAIL` for every assertion, along with a description of what was verified.

---

## 🛠️ Usage

### Compilation

#### Option 1: Using `make`

Compile the entire project (including tests):

```bash
make all
```

Compile and run tests:

```bash
make test
```

Clean object and binary files:

```bash
make clean
```

#### Option 2: Using `gnatmake` Directly

Compile the package:

```bash
gnatmake -P exponential_backoff.gpr
```

Compile and run tests:

```bash
gnatmake -o bin/tests tests.adb
bin/tests
```

#### Option 3: Using the GNAT Project File

The `exponential_backoff.gpr` file defines the project structure. To compile with custom options:

```bash
gnatmake -P exponential_backoff.gpr -O2 -g
```

---

### Example Usage

#### 1. Deterministic Exponential Backoff

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Config : Backoff_Config := (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);
   Delay : Delay_Type;
begin
   Delay := Deterministic_Backoff(Config, 3); -- Returns 8 (2^3 * 1)
end Example;
```

#### 2. Randomized Exponential Backoff (Collision Avoidance)

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Config : Backoff_Config := (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);
   Delay : Delay_Type;
begin
   Delay := Randomized_Backoff(Config, 3); -- Returns a random delay in [0, 7] * 512
end Example;
```

#### 3. Binary Exponential Backoff (BEB)

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Delay : Delay_Type;
begin
   Delay := Binary_Exponential_Backoff(3); -- Returns 4096 (2^3 * 512)
end Example;
```

#### 4. Truncated Exponential Backoff

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Config : Backoff_Config := (Base => 2, Max_Retries => 5, Initial_Delay => 1, Slot_Time => 512);
   Delay : Delay_Type;
begin
   Delay := Truncated_Backoff(Config, 10); -- Returns 32 (capped at 2^5 * 1)
end Example;
```

#### 5. Adaptive Backoff (Heuristic RCP)

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Delay : Delay_Type;
begin
   Delay := Adaptive_Backoff(2); -- Returns 100 (K(2) = 100)
end Example;
```

#### 6. Expected Backoff

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Expected : Delay_Type;
begin
   Expected := Expected_Backoff(3); -- Returns 3 ((2^3 - 1)/2)
end Example;
```

#### 7. Recovery Mechanism

```ada
with Exponential_Backoff; use Exponential_Backoff;

procedure Example is
   Current_Count : Collision_Count_Type := 5;
   New_Count : Collision_Count_Type;
begin
   New_Count := Reset_Backoff(Current_Count, True); -- Returns 0 (reset after cooling-off)
end Example;
```

---

## 📂 File Structure

```
RobertBoettcherSF__Ada-Exponential-Backoff/
├── exponential_backoff.ads    # Package specification (types, exceptions, declarations)
├── exponential_backoff.adb    # Package body (implementations)
├── exponential_backoff.gpr    # GNAT Project File
├── tests.adb                  # Test suite (13+ tests)
├── Makefile                   # Compilation and test automation
├── obj/                       # Object files (generated by compiler)
├── bin/                       # Executables (generated by compiler)
└── README.md                  # Project documentation
```

---

## 🔧 Configuration

The `Backoff_Config` type allows customization of the algorithm:

```ada
type Backoff_Config is record
   Base          : Base_Type := 2;       -- Multiplicative factor (default: 2 for BEB)
   Max_Retries   : Max_Retries_Type := 10; -- Maximum retry attempts (for truncated)
   Initial_Delay : Delay_Type := 1;     -- Initial delay (e.g., 1 slot time)
   Slot_Time     : Delay_Type := 512;   -- Slot time (e.g., 51.2 µs in Ethernet, scaled to 512)
end record;
```

A default configuration for Binary Exponential Backoff (BEB) is provided:

```ada
Default_BEB_Config : constant Backoff_Config := 
  (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);
```

---

## 📚 Algorithm Details

### Mathematical Formulations

| Variant | Formula | Description |
|---------|---------|-------------|
| **Deterministic** | `t = b^c * initial_delay` | Fixed delay after `c` collisions |
| **Randomized** | `t = random(0, b^c - 1) * slot_time` | Random delay for collision avoidance |
| **Truncated** | `t = b^min(c, max_retries) * initial_delay` | Caps delay at `max_retries` |
| **Binary (BEB)** | `t = 2^c * slot_time` | Special case with `b = 2` |
| **Adaptive (RCP)** | `K(m)` increases with `m` (e.g., 1, 10, 100, 200) | Lam's Heuristic RCP |
| **Expected** | `E(c) = (b^c - 1) / 2` | Expected delay for randomized backoff |

### Example: Ethernet CSMA/CD

In Ethernet (IEEE 802.3), the **Truncated Binary Exponential Backoff** algorithm is used:

1. After the first collision, wait **0 or 1 slot times** (51.2 µs each).
2. After the second collision, wait **0 to 3 slot times**.
3. After the third collision, wait **0 to 7 slot times**.
4. ...
5. After the 10th collision, wait **0 to 1023 slot times** (capped at 10).

This is implemented in the `Truncated_Backoff` function with `Max_Retries = 10`.

---

## 🛡️ Error Handling

The package defines the following exceptions:

| Exception | Description | When Raised |
|-----------|-------------|-------------|
| `Retry_Limit_Exceeded` | Maximum retries exceeded | Not used (truncated backoff caps instead) |
| `Invalid_Base` | Base must be >= 2 | `Validate_Config` if `Base < 2` |
| `Invalid_Collision_Count` | Collision count cannot be negative | Not used (type constraints prevent this) |

---

## ⚠️ Limitations

- **Type Ranges**: 
  - `Base_Type`: `2 .. 100` (cannot be 1 or > 100).
  - `Max_Retries_Type`: `1 .. 100`.
  - `Collision_Count_Type`: `0 .. 100`.
  - `Delay_Type`: `0 .. 2^31 - 1` (may overflow for very large exponents).
- **Overflow Risk**: For large `Collision_Count` values (e.g., > 30 with `Base=2`), `Compute_Power` may overflow `Delay_Type`.
- **Randomness**: `Randomized_Backoff` uses a pseudo-random number generator (not cryptographically secure).

---

## 📊 Performance Notes

- **Time Complexity**: `Compute_Power` uses iterative multiplication (`O(c)` for `c` collisions).
- **Space Complexity**: `O(1)` for all functions (no dynamic allocation).
- **Randomness**: `Randomized_Backoff` uses `Ada.Numerics.Discrete_Random` for uniform random delays.

---

## 🤝 Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a Pull Request.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Wikipedia**: [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff) for the algorithm descriptions.
- **Norman Abramson**: Inventor of the ALOHA protocol, which inspired exponential backoff.
- **Leonard Kleinrock and Simon Lam**: Pioneers in adaptive backoff algorithms.
- **IEEE 802.3**: Standard for Ethernet CSMA/CD, which uses truncated binary exponential backoff.
