# Nagle's Algorithm in Ada

## 📌 Project Overview

This repository provides a **complete Ada implementation** of **Nagle's Algorithm** (RFC 896) and its variants for TCP/IP congestion control. Nagle's Algorithm improves network efficiency by addressing the "small-packet problem" where applications send data in tiny chunks (often just 1 byte), resulting in inefficient use of network bandwidth due to TCP/IP headers (40 bytes per packet).

### What is Nagle's Algorithm?

Nagle's Algorithm is a **congestion control mechanism** defined by John Nagle in [RFC 896](https://tools.ietf.org/html/rfc896) (1984). It works by:

1. **Buffering small outgoing messages** when there is unacknowledged data in the network
2. **Sending buffered data in larger chunks** when either:
   - The buffer accumulates enough data to fill a Maximum Segment Size (MSS) packet, **or**
   - An acknowledgment is received for previously sent data

This reduces the number of small packets on the network, improving efficiency and preventing congestion collapse.

### Why This Implementation?

This Ada implementation provides:
- **Strong typing** for all algorithm-specific data
- **All variants** of Nagle's Algorithm mentioned in RFC 896 and related literature
- **Comprehensive testing** with 14 test cases covering edge cases and interactions
- **Modular design** with separate procedures for each variant

## ✨ Features

### Implemented Variants

| Variant | Description | Use Case |
|---------|-------------|----------|
| **Original Nagle** | Strict buffering until MSS or ACK | General TCP applications |
| **Minshall's Modification** | Sends full-sized packets immediately | HTTP and similar protocols |
| **No Nagle (TCP_NODELAY)** | Immediate sending, no buffering | Low-latency applications |

### Key Components

- **Packet Type**: Represents TCP packets with dynamic data buffers
- **Buffer Management**: Uses Ada.Containers.Vectors for efficient packet buffering
- **Memory Management**: Proper allocation and deallocation of dynamic arrays
- **Delayed ACK Simulation**: Models the interaction between Nagle's Algorithm and TCP Delayed ACK

### Algorithm Details

#### Original Nagle's Algorithm
```
IF there is new data to send THEN
    IF window size ≥ MSS AND buffered data ≥ MSS THEN
        send complete MSS segment now
        clear buffer
    ELSE IF there is unacknowledged data THEN
        buffer the new data
    ELSE
        send data immediately
    END IF
END IF
```

#### Minshall's Modification
Same as Original Nagle, **except**:
- If the last packet in the buffer is full-sized (MSS), send new data immediately
- This reduces the "large-write penalty" in protocols like HTTP

#### No Nagle (TCP_NODELAY)
- Always sends data immediately without buffering
- Used for low-latency applications (games, remote desktop)

## 🧪 Testing

### Test Philosophy

The test suite assumes the code is **broken** and aims to **disprove this assumption** (PASS = code works correctly). This pessimistic approach ensures robust validation of the implementation.

### Test Coverage

The suite includes **14 comprehensive tests** covering:

1. **Functional Correctness** (Tests 1-7)
   - Original Nagle logic (send/buffer conditions)
   - Minshall's modification behavior
   - No Nagle immediate sending
   - Empty data handling

2. **Helper Functions** (Tests 8-9)
   - `Has_Enough_Data` function
   - `Merge_Packets` function

3. **Edge Cases** (Tests 10-11)
   - Empty buffer
   - Zero window size

4. **Delayed ACK Interaction** (Test 12)
   - Timeout simulation

5. **Large Data Handling** (Tests 13-14)
   - Data larger than MSS
   - Partial last packet handling

### Why These Tests Matter

- **Verification**: Ensures code matches RFC 896 and variant specifications
- **Validation**: Confirms the algorithm works for real-world TCP scenarios
- **Reliability**: Catches regressions in buffering logic or packet merging
- **Safety**: Prevents infinite buffering or incorrect packet drops

### Running Tests

```bash
make test
```

Output will show `PASS`/`FAIL` for each assertion:
```
TEST 1 - Original Nagle: No Unacked Data
  1.1 Send_Now = True: PASS
  1.2 Packet_To_Send.Size = 3: PASS
  1.3 Buffer is empty: PASS

TEST 2 - Original Nagle: Unacked Data Exists
  2.1 Send_Now = False: PASS
  ...
```

## 🚀 Usage

### Prerequisites

- **GNAT Ada Compiler** (part of GCC)
- **GNU Make**

Install on Ubuntu/Debian:
```bash
sudo apt-get install gnat make
```

### Compilation

#### Option 1: Using Makefile (Recommended)
```bash
make
```
This will:
1. Create `obj/` and `bin/` directories
2. Compile all source files
3. Generate executables in `bin/`

#### Option 2: Manual Compilation
```bash
# Compile the demo
gnatmake -o bin/nagle_demo main.adb

# Compile the tests
gnatmake -o bin/tests tests.adb
```

### Running the Demo

```bash
./bin/nagle_demo
```

Expected output:
```
=== Nagle's Algorithm Demo ===

Original Nagle:
  Send_Now: TRUE
  Packet Size:  10

Minshall Nagle:
  Send_Now: FALSE
  Packet Size:  10

No Nagle (TCP_NODELAY):
  Send_Now: TRUE
  Packet Size:  10
```

### Using the Library

To use this implementation in your own Ada project:

1. Include the specification:
   ```ada
   with Nagle; use Nagle;
   ```

2. Example usage:
   ```ada
   declare
      MSS : Natural := 1460;
      Window_Size : Natural := 2920;
      Unacked : Unacknowledged_Flag := No_Unacked;
      Buffer : Packet_Vectors.Vector;
      Send_Now : Boolean;
      Packet_To_Send : Packet;
      Data : Buffer_Type := (1 .. 10 => 0);
   begin
      -- Use Original Nagle
      Original_Nagle(MSS, Window_Size, Unacked, Data, Buffer, Send_Now, Packet_To_Send);
      
      -- Don't forget to free memory!
      Free_Packet(Packet_To_Send);
   end;
   ```

## 📁 File Structure

```
.
├── nagle.ads          # Package specification with types and declarations
├── nagle.adb          # Package body with algorithm implementations
├── tests.adb          # Comprehensive test suite (14 tests)
├── main.adb           # Demo program showcasing all variants
├── Makefile           # Build automation
├── nagle.gpr          # GNAT Project File (optional)
├── obj/               # Directory for object files
├── bin/               # Directory for executables
└── README.md          # This documentation file
```

## 📚 Background Information

### The Small-Packet Problem

In early TCP/IP networks, applications like Telnet would send data one byte at a time (e.g., for each keystroke). With a 40-byte TCP/IP header, this resulted in:
- 41-byte packets for 1 byte of data
- **97.5% overhead!**
- Potential for congestion collapse on slow links

Nagle's Algorithm solves this by buffering small packets and sending them in larger chunks.

### Interaction with Delayed ACK

TCP Delayed ACK (introduced in the 1980s) waits up to 500ms before sending acknowledgments to reduce ACK traffic. This can interact poorly with Nagle's Algorithm:

- **Problem**: Applications performing `write-write-read` sequences experience constant 500ms delays
- **Solution**: Disable either Nagle (via `TCP_NODELAY`) or Delayed ACK (via `TCP_QUICKACK`)

Nagle recommends disabling Delayed ACK rather than his algorithm, as "quick" ACKs have less overhead than many small packets.

### Minshall's Modification

Greg Minshall proposed a modification to address the "large-write penalty":
- Always send if the last packet is full-sized
- Only wait for acknowledgment if the last packet is partial

This reduces the incentive to disable Nagle's Algorithm entirely.

## 🔗 References

- [RFC 896: Congestion Control in IP/TCP Internetworks](https://tools.ietf.org/html/rfc896)
- [Wikipedia: Nagle's Algorithm](https://en.wikipedia.org/wiki/Nagle%27s_algorithm)
- [TCP_NODELAY and Delayed ACK](https://en.wikipedia.org/wiki/TCP_tuning)

## 📜 License

This implementation is provided as-is for educational and research purposes. It demonstrates the principles of Nagle's Algorithm and its variants in Ada.

---

**Maintained by**: Robert Boettcher
**Last Updated**: 2024
