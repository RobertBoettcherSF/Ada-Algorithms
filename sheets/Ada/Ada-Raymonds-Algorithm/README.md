# Raymond's Algorithm in Ada

## Project Overview

This repository provides a strict, type-safe Ada implementation of **Raymond's Algorithm**, a robust algorithm used to achieve distributed mutual exclusion in a computer network. The nodes operate in an unrooted tree topology pointing toward the current token holder. A node can only enter its Critical Section (CS) when it holds the token.

## Algorithm Overview

Raymond's Algorithm is a token-based distributed mutual exclusion algorithm for tree-structured networks. Each node maintains a pointer toward the current token holder, forming a tree topology. The algorithm ensures that:

1. **Safety**: At most one node can be in the critical section at any time
2. **Liveness**: Every request is eventually granted
3. **Efficiency**: Minimal message passing between nodes

### How It Works
- Each node maintains a queue of pending requests
- To enter the critical section, a node must possess the token
- If a node doesn't have the token, it sends a request upward toward the token holder
- The token holder processes requests in FIFO order, passing the token to the next node
- When a node releases the critical section, it passes the token to the next queued node

## Features

- **Strict Data Typing**: Strong domain boundaries preventing ID spoofing or Message malformation
- **Variant 1: Standard Protocol**: Pure FIFO queueing and propagation exactly as defined in Raymond's standard algorithmic paper
- **Variant 2: Greedy Network Protocol**: An optimized algorithmic variant (`Greedy_Receive_Request`) that suppresses duplicate node requests to minimize token-network saturation
- **Deterministic Modeling**: Isolated state transitions allow for 100% reproducible testing
- **Comprehensive Error Handling**: Queue overflow/underflow exceptions with clear semantics

## Prerequisites

- **GNAT Ada compiler** (part of GCC)
- **GNU Make**

### Installation on Debian/Ubuntu:

```bash
sudo apt-get install gnat make
```

### Installation on Fedora/RHEL:

```bash
sudo dnf install gcc-gnat make
```

### Installation on macOS (using Homebrew):

```bash
brew install gnat make
```

## Project Structure

```
.
├── raymonds_algorithm.ads    # Package specification (types and interfaces)
├── raymonds_algorithm.adb    # Package body (implementation)
├── main.adb                  # Demonstration program
├── tests.adb                 # Comprehensive test suite
├── raymonds.gpr              # GNAT Project file
├── Makefile                  # Build configuration
└── README.md                 # This file
```

## Available Make Targets

| Target | Description |
|--------|-------------|
| `make all` | Build both main and test executables |
| `make test` | Build and run the test suite |
| `make clean` | Remove all object and binary files |

## Usage

### Compilation

The codebase uses a standard Makefile orchestrating GNAT tools. To build the executables:

```bash
make all
```

Or to build and run tests:

```bash
make test
```

### Running the Demonstration

```bash
make all
./bin/main
```

Expected output:
```
--- Raymond's Algorithm Simulation ---
[*] Node B requests Critical Section locally...
    -> Emitted: REQUEST_MSG | Sender= 2 | Receiver= 1
[*] Node A receives Request from Node B...
    -> Emitted: TOKEN_MSG | Sender= 1 | Receiver= 2
--- Simulation Complete ---
```

### Running the Tests

```bash
make test
```

Expected output:
```
Running tests...
===============================================
    RAYMOND'S ALGORITHM V&V TEST SUITE
 Philosophy: Assume code is functionally broken
 PASS = Assumption disproven by assertions
===============================================
TEST 1 - Initialization Logic
  1.1 [Assertion: Node fails to retain valid ID]
      PASS: Node correctly retains ID.
  1.2 [Assertion: Node misconfigures Holder address]
      PASS: Node correctly sets Holder.
  1.3 [Assertion: Node defaults to unsafe CS usage]
      PASS: Node is out of CS on start.
TEST 2 - FIFO Queue Reliability
  2.1 [Assertion: Queue fails to increment count on Enqueue]
      PASS: Queue count behaves predictably.
  2.2 [Assertion: Queue scrambles FIFO Dequeue order]
      PASS: Strict FIFO order maintained.
  2.3 [Assertion: Dequeuing empty queue causes memory corruption]
      PASS: Caught intentional Queue_Underflow exception.
TEST 3 - Token Holder Local Request
  3.1 [Assertion: Token Holder fails to assign token to itself]
      PASS: Token holder skips network, grabs CS.
  3.2 [Assertion: Token Holder spams network asking for own token]
      PASS: No phantom messages emitted.
TEST 4 - Leaf Node Network Request
  4.1 [Assertion: Leaf forgets to enqueue its own request]
      PASS: Leaf request properly enqueued.
  4.2 [Assertion: Leaf drops the Request Message]
      PASS: Request message accurately structured and emitted.
  4.3 [Assertion: Leaf forgets 'Asked' state, risking network flood]
      PASS: Asked state prevents duplicate requests.
TEST 5 - Standard Message Reception
  5.1 [Assertion: Node ignores incoming requests]
      PASS: Request safely enqueued.
  5.2 [Assertion: Node drops routing responsibility]
      PASS: Node routed Request upward.
TEST 6 - Greedy Variant Network Optimization
  6.1 [Assertion: Greedy algorithm fails to drop duplicate requests]
      PASS: Variant correctly suppressed duplicate network request.
===============================================
 ALL V&V ASSUMPTIONS DISPROVEN - SYSTEM STABLE
```

## Testing

This project follows strict **Verification and Validation (V&V)** paradigms suitable for safety-critical systems.

**Philosophy:** We approach the test suite under the assumption that the code is functionally broken. Tests **PASS** only when the code definitively disproves our pessimistic assumptions.

### Test Categories Verified:

1. **Functional Initialization**: Verifies the baseline state vector. *(Proves memory is not corrupted or unsafely defaulting.)*
2. **Data Structure Bounds**: Tests Queue Enqueue/Dequeue operations and boundary conditions (Overflow/Underflow). *(Proves catastrophic queue degradation cannot occur.)*
3. **Control Flow (Root)**: Assesses token-holder responses to local CS requests. *(Proves the system avoids generating spam messaging when no routing is required.)*
4. **Network Flow (Leaf/Routing)**: Validates correct routing behavior and 'Asked' state toggles. *(Proves nodes accurately route Requests without flooding the network.)*
5. **Algorithmic Variants**: Verifies that the Greedy Protocol successfully suppresses duplicate payload generation. *(Proves the variant reduces network load efficiently.)*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## References

- Raymond, K. (1989). "A Tree-Based Algorithm for Distributed Mutual Exclusion"
