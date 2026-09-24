# Ada Implementation of Karn's Algorithm

![Karn's Algorithm](https://img.shields.io/badge/Algorithm-Karn's%20Algorithm-blue)
![Language](https://img.shields.io/badge/Language-Ada-green)
![License](https://img.shields.io/badge/License-MIT-orange)

---

## 📌 Project Overview

This repository contains a **complete Ada implementation** of **Karn's Algorithm** (also known as the **Karn-Partridge Algorithm**), a fundamental algorithm for **Round-Trip Time (RTT) estimation** in TCP (Transmission Control Protocol). The algorithm was proposed by **Phil Karn and Craig Partridge in 1987** to address the ambiguity in RTT estimation caused by retransmitted segments.

### What Problem Does It Solve?
In TCP, RTT is estimated as the time difference between sending a segment and receiving its acknowledgment (ACK). However, when a segment is **retransmitted**, the ACK received could correspond to either:
- The **original transmission**, or
- The **retransmission**.

This ambiguity makes it difficult to accurately estimate RTT. Karn's Algorithm resolves this by **ignoring retransmitted segments** when updating RTT estimates and only using **unambiguous ACKs** (ACKs for segments sent exactly once).

### Why Is This Important?
Accurate RTT estimation is critical for:
- **Timeout calculation**: TCP uses RTT to determine when to retransmit lost segments.
- **Congestion control**: RTT helps detect network congestion and adjust transmission rates.
- **Flow control**: RTT is used to optimize data transmission efficiency.

Without Karn's Algorithm, TCP could use stale or incorrect RTT estimates, leading to **unnecessary retransmissions** or **poor performance** in networks with high packet loss or variable delays.

---

## 🚀 Features

### Implemented Variants
1. **Basic Karn's Algorithm**:
   - Ignores retransmitted segments when updating RTT estimates.
   - Only updates RTT for **unambiguous ACKs** (segments sent once).
   - Uses exponential smoothing for RTT estimates.

2. **Karn's Algorithm with Jacobson's Smoothing**:
   - Extends the basic variant with **Jacobson's algorithm** for smoothing RTT and deviation estimates.
   - Uses two smoothing factors: `Alpha` (for RTT) and `Beta` (for deviation).
   - Calculates timeout as `Smoothed_RTT + 4 * Dev_RTT` (standard in TCP).

3. **Timer Backoff Strategy**:
   - Doubles the timeout value on each retransmission (exponential backoff).
   - Prevents stale RTT estimates in cases where all segments are retransmitted.

### Key Components
| Component | Description |
|-----------|-------------|
| `Segment` | Represents a TCP segment with sequence number, send time, status, and retransmit count. |
| `ACK` | Represents an acknowledgment with ACK number and receive time. |
| `RTT_Data` | Stores RTT estimates, smoothed RTT, timeout, and smoothing factors (`Alpha`, `Beta`). |
| `Transmission_Status` | Enumeration for `First_Transmission` and `Retransmitted`. |

### Procedures and Functions
| Procedure/Function | Description |
|-------------------|-------------|
| `Initialize_RTT_Data` | Initializes RTT data with default values. |
| `Calculate_RTT` | Computes RTT for a segment and its ACK. |
| `Update_RTT_Estimate` | Updates RTT estimate for unambiguous ACKs (basic variant). |
| `Update_RTT_With_Smoothing` | Updates RTT estimate with Jacobson's smoothing. |
| `Handle_Retransmission` | Marks a segment as retransmitted and applies backoff. |
| `Handle_Timeout` | Doubles the timeout value on timeout. |
| `Reset_Timeout` | Resets timeout to its initial value. |
| `Is_Unambiguous_ACK` | Checks if an ACK is unambiguous. |
| `Simulate_Karns_Algorithm` | Simulates Karn's Algorithm for arrays of segments and ACKs. |
| `Simulate_Karns_Algorithm_With_Backoff` | Simulates Karn's Algorithm with timer backoff. |
| `Are_Arrays_Valid` | Validates segment and ACK arrays for consistency. |
| `Find_Segment_For_ACK` | Finds the segment matching an ACK. |

---

## 📜 Algorithm Explanation

### Core Idea
Karn's Algorithm ensures that **RTT estimates are only updated using unambiguous ACKs** (ACKs for segments sent exactly once). This avoids the ambiguity introduced by retransmissions.

### Steps
1. **Send a Segment**:
   - Record the segment's `Sequence_Number`, `Send_Time`, and `Status` (initially `First_Transmission`).

2. **Receive an ACK**:
   - If the ACK matches a segment with `Status = First_Transmission`, calculate RTT and update the estimate.
   - If the ACK matches a retransmitted segment, **ignore it** for RTT updates.

3. **Handle Retransmissions**:
   - If a timeout occurs, mark the segment as `Retransmitted` and **double the timeout** (exponential backoff).
   - This ensures the RTT estimate eventually adapts to new network conditions.

4. **Update RTT Estimate**:
   - For the **basic variant**, use exponential smoothing:
     ```
     New_RTT_Estimate = Alpha * RTT + (1 - Alpha) * Old_RTT_Estimate
     Timeout = 2 * RTT_Estimate
     ```
   - For the **Jacobson variant**, use:
     ```
     Smoothed_RTT = (1 - Alpha) * Smoothed_RTT + Alpha * RTT
     Dev_RTT = (1 - Beta) * Dev_RTT + Beta * |RTT - Smoothed_RTT|
     Timeout = Smoothed_RTT + 4 * Dev_RTT
     ```

### Example
Suppose:
- Segment 1 is sent at `t=0` with `Status = First_Transmission`.
- ACK for Segment 1 is received at `t=0.1`.
- RTT = `0.1 - 0 = 0.1` seconds.
- RTT estimate is updated to `0.1`.
- Timeout is set to `0.2` seconds (`2 * RTT`).

If Segment 1 is retransmitted:
- Segment 1 is marked as `Retransmitted`.
- ACK for the retransmission is **ignored** for RTT updates.
- Timeout is doubled to `0.4` seconds (backoff).

---

## 🛠️ Usage

### Compilation
To compile the Karn's Algorithm library and test suite, use the provided `Makefile`:

```bash
# Compile everything (library + tests)
make all

# Compile and run tests
make test

# Clean compiled files
make clean
```

Alternatively, compile manually using `gnatmake`:

```bash
# Compile the library
gnatmake -o bin/karns_algorithm karns_algorithm.adb

# Compile the test suite
gnatmake -o bin/tests tests.adb
```

### Running Tests
To run the test suite:

```bash
make test
```

This will:
1. Compile the test suite (if not already compiled).
2. Execute all 14 tests.
3. Print **PASS/FAIL** results for each test.

#### Expected Output
```
=== Karn's Algorithm Test Suite ===

TEST 1 - Basic RTT Calculation
  1.1 PASS
  1.2 PASS
  1.3 PASS

TEST 2 - Unambiguous ACK Check
  2.1 PASS
  2.2 PASS
  2.3 PASS

...

=== All Tests Completed ===
```

### Using the Library
To use the Karn's Algorithm library in your own Ada program:

1. **Include the Specification**:
   ```ada
   with Karns_Algorithm; use Karns_Algorithm;
   ```

2. **Initialize RTT Data**:
   ```ada
   RTT_Data : Karns_Algorithm.RTT_Data;
   Initialize_RTT_Data(RTT_Data);
   ```

3. **Create Segments and ACKs**:
   ```ada
   Seg : Segment := (Sequence_Number => 1, Send_Time => Clock, Status => First_Transmission, Retransmit_Count => 0);
   Ack : ACK := (ACK_Number => 1, Receive_Time => Clock);
   ```

4. **Update RTT Estimate**:
   ```ada
   Update_RTT_Estimate(Seg, Ack, RTT_Data);
   ```

5. **Handle Retransmissions and Timeouts**:
   ```ada
   Handle_Retransmission(Seg, RTT_Data);  -- Mark as retransmitted and apply backoff
   Handle_Timeout(RTT_Data);               -- Double timeout on timeout
   ```

#### Full Example
```ada
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Karns_Algorithm; use Karns_Algorithm;

procedure Example is
   Seg : Segment;
   Ack : ACK;
   RTT_Data : RTT_Data;
   Start_Time : Time := Clock;
begin
   -- Initialize RTT data
   Initialize_RTT_Data(RTT_Data);
   
   -- Send a segment
   Seg := (Sequence_Number => 1, Send_Time => Start_Time, Status => First_Transmission, Retransmit_Count => 0);
   
   -- Simulate receiving an ACK after 100ms
   delay 0.1;
   Ack := (ACK_Number => 1, Receive_Time => Clock);
   
   -- Update RTT estimate
   Update_RTT_Estimate(Seg, Ack, RTT_Data);
   
   -- Print results
   Put_Line("RTT Estimate: " & RTT_Data.Current_RTT_Estimate'Image);
   Put_Line("Timeout: " & RTT_Data.Timeout'Image);
end Example;
```

---

## 🧪 Testing

### Test Philosophy
The test suite is designed under the **pessimistic assumption that the code is broken**. Each test aims to **disprove this assumption** by verifying correct behavior. A test **PASSes** when it demonstrates that the code works as expected.

### Test Categories
The test suite includes **14 tests** covering:

| Category | Tests | Description |
|----------|-------|-------------|
| **Functional Correctness** | 1-4 | Verify core functionality (RTT calculation, unambiguous ACK checks, RTT updates). |
| **Error Handling** | 5-6, 10 | Test exceptions for invalid inputs (mismatched ACKs, retransmissions). |
| **Edge Cases** | 7-9, 11-13 | Test empty arrays, single segment/ACK, all retransmitted segments. |
| **Robustness** | 14 | Test timeout reset functionality. |
| **Simulation** | 7-8 | End-to-end testing of Karn's Algorithm with and without backoff. |

### Why These Tests Matter
1. **Verification**:
   - The tests verify that the implementation adheres to the **requirements** of Karn's Algorithm (e.g., ignoring retransmitted segments, updating RTT only for unambiguous ACKs).

2. **Validation**:
   - The tests validate that the code meets its **intended use** in real-world scenarios (e.g., handling retransmissions, adjusting timeouts dynamically).

3. **Reliability**:
   - By testing edge cases and error conditions, the suite ensures the code is **robust** and **safe** for critical systems (e.g., networking protocols, embedded systems).

4. **Correctness**:
   - The tests prove that the code works correctly **despite the initial pessimistic assumption**, providing confidence in its correctness.

### Test Results
Each test prints **PASS** or **FAIL** to the terminal, along with a descriptive message. Example:
```
TEST 1 - Basic RTT Calculation
  1.1 PASS
  1.2 PASS
  1.3 PASS
```

---

## 📁 File Structure

```
Ada-Karn-Algorithm/
├── karns_algorithm.ads       # Package specification (types, exceptions, declarations)
├── karns_algorithm.adb       # Package body (implementations)
├── karns_algorithm.gpr       # GNAT Project File for compilation
├── tests.adb                 # Test suite with 14 terminal-executable tests
├── Makefile                  # Makefile for compilation and testing
├── obj/                      # Directory for object files
├── bin/                      # Directory for executables
└── README.md                 # Project documentation
```

---

## 🔍 Verification and Validation (V&V) Principles

This implementation adheres to **V&V principles** for critical systems:

### Verification
- The code is **verified** against the requirements of Karn's Algorithm.
- The test suite ensures the implementation matches the **specified behavior** of the algorithm.
- All edge cases (e.g., empty arrays, retransmitted segments) are handled correctly.

### Validation
- The code is **validated** for its intended use in real-world scenarios.
- The test suite includes **14 tests** covering functional correctness, error handling, and robustness.
- The algorithm is tested under **pessimistic assumptions** (code is broken until proven otherwise).

### Key V&V Concepts Applied
| Concept | Application |
|---------|-------------|
| **Correctness** | Tests verify the code produces the correct RTT estimates and timeout values. |
| **Robustness** | Tests cover edge cases (empty arrays, all retransmitted segments). |
| **Reliability** | The algorithm handles retransmissions and timeouts gracefully. |
| **Safety** | Exceptions are raised for invalid inputs (e.g., mismatched ACKs). |
| **Modularity** | The code is divided into small, testable procedures and functions. |

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Phil Karn and Craig Partridge**: For proposing Karn's Algorithm in 1987.
- **Van Jacobson**: For developing the smoothing algorithm used in TCP.
- **Ada Language**: For its strong typing and reliability features, making it ideal for critical systems.

---

## 📞 Contact

For questions or feedback, please open an issue on the [GitHub repository](https://github.com/RobertBoettcherSF/Ada-Karn-Algorithm).
