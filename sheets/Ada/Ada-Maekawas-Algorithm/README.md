# Maekawa's Distributed Mutual Exclusion Algorithm in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of Maekawa's algorithm for mutual exclusion in distributed systems. It utilizes an event-driven simulation architecture to model distributed message passing and exercise both the basic and deadlock-free variants of the algorithm.

## Features
- **Grid Quorum Construction**: Dynamically generates optimally intersecting sets O(√N) per coterie definitions.
- **Basic Queueing Variant**: Defers competing requests via Timestamp-based priority queues.
- **Deadlock-Free Variant**: Implements `INQUIRE`, `FAIL`, and `YIELD` message states to detect and resolve circular waits and priority inversions.
- **Strongly Typed Architecture**: Uses restricted range subtypes (`Valid_Node_Id`), explicit state machines, and priority-enforced event queues.

## Testing (V&V Principles)
Verification and Validation (V&V) ensures that the implementation conforms to the algorithmic requirements and behaves correctly under adversarial conditions. The included test harness (tests.adb) encodes pessimistic assumptions and asserts that the system disproves them.

### Test Categories
1. **Functional Correctness (Tests 1-5):** Memory initialization, accurate √N quorum sizing, and intersection properties for coteries. 
2. **Mutual Exclusion Constraints (Tests 6-8):** Validates safety — no two nodes can be `Holding` at once.
3. **Edge Cases & Priorities (Test 9):** Verifies temporal priority inversion handling when later-arriving requests have higher priority.
4. **Error Handling & Deadlock Avoidance (Tests 10-13):** Confirms generation and handling of `INQUIRE`, `FAIL`, and `YIELD` to prevent permanent deadlocks.

*Why this matters:* In distributed embedded systems (Ada's primary domain), a failure in mutual exclusion can lead to data corruption; Deadlock avoidance ensures forward progress.

## Quick start

Prerequisites:
- GNAT (gnatmake / gprbuild). GNAT Community 2020 or later is recommended.

Build & run tests:
```bash
make test
```

Build & run example:
```bash
make all
./bin/main
```

## Configuration & Debugging
- To enable verbose debug traces set `Debug_Enable := True;` in `maekawa.adb`. Debug output prints event lifecycle and handler actions useful while diagnosing TEST 10–13.

- Important constants (see `maekawa.ads`):
  - `Max_Nodes` (default 9): number of simulated nodes (3x3 grid quorum variant). Adjust carefully — both the spec and body must be updated.
  - `Max_Events` (default 1000): capacity of the simulated event queue.

## Design notes and invariants
Key invariants and design choices:
- `Replies_Count` counts votes/grants collected by a requester (includes implicit self-grant when applicable).
- `Voted` indicates whether a voter currently has an outstanding grant; `Voted_For` stores the grantee's node id.
- `Inquired` is used to avoid repeated INQUIRE messages to the same voter until a YIELD or Release clears it.
- INQUIRE / YIELD are treated as higher-priority events in the simulator to promptly break circular waits.

## API summary (see `maekawa.ads`)
- Initialize(System) — zeroes system state
- Generate_Grid_Quorums(System) — constructs 3x3 grid quorums (update with Max_Nodes changes)
- Request_CS(System, Node, TS) — request critical section with timestamp TS
- Release_CS(System, Node) — release CS and process queued requests
- Process_Next_Event / Process_All_Events — network simulator drivers

## Contributing / Extending
- If you change `Max_Nodes`, update both `maekawa.ads` and `maekawa.adb` (quorum generation assumes a square grid).
- Add new tests to `tests.adb` following the existing V&V style: the harness asserts assumptions are false and raises Program_Error on failure.

## License
This project is provided under the LICENSE file in the repository.
