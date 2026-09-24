# Truncated Binary Exponential Backoff (TBEB) in Ada

## Project Overview

This repository implements the **Truncated Binary Exponential Backoff (TBEB)** algorithm in Ada, as described in the [Wikipedia article](https://en.wikipedia.org/wiki/Truncated_binary_exponential_backoff). The algorithm is widely used in network protocols (e.g., Ethernet CSMA/CD, IEEE 802.3) to avoid collisions by exponentially increasing the delay between retransmission attempts after each failure, up to a maximum limit (ceiling).

## Features

- **Deterministic BEB**: Fixed delay calculation (`delay = base^c * slot_time`).
- **Randomized BEB**: Random delay in `[0, base^c - 1] * slot_time` for collision avoidance.
- **Truncated BEB**: Limits the exponent `c` to a ceiling to avoid unbounded delays.
- **Static/Dynamic Ceiling**: Configurable ceiling for truncation.
- **State Management**: Track collision counts and current delays.
- **Expected Delay Calculation**: Compute the expected delay for randomized BEB.
- **Validation**: Check for invalid configurations (e.g., `base < 2`, `slot_time <= 0`).
- **Helper Functions**: `Power_Of_Two`, `Clamp_Collision_Count`, etc.

## Quick Start

### Prerequisites

Ensure you have the **GNAT Ada compiler** installed:

```bash
# On Debian/Ubuntu:
sudo apt-get install gnat gprbuild

# On Fedora/RHEL:
sudo dnf install gcc-gnat

# On macOS (using Homebrew):
brew install gnat
```

### Compilation

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-Truncated-Binary-Exponential-Backoff.git
cd Ada-Truncated-Binary-Exponential-Backoff

# Compile and run tests
make clean && make test
```

### Running Tests

```bash
# Method 1: Using make
make test

# Method 2: Direct execution
make
./bin/tests
```

## API Reference

### Types

| Type | Description | Range |
|------|-------------|-------|
| `Slot_Time_Type` | Time unit for slot time (e.g., microseconds) | 0 .. Integer'Last |
| `Delay_Type` | Delay values in slot times or absolute units | 0 .. Integer'Last |
| `Collision_Count_Type` | Number of collisions encountered | 0 .. Integer'Last |
| `Base_Type` | Base of the exponential function (must be >= 2) | 2 .. Integer'Last |
| `Ceiling_Type` | Maximum exponent value for truncation | 0 .. Integer'Last |

### Configuration

```ada
-- Default IEEE 802.3 configuration
Default_Config : constant Backoff_Config := (
   Base      => 2,
   Ceiling   => 10,
   Slot_Time => 512
);
```

### Core Functions

#### Delay Calculation

| Function | Description | Parameters |
|----------|-------------|------------|
| `Deterministic_Delay` | Calculates fixed delay: `base^c * slot_time` | Config, C |
| `Randomized_Delay` | Calculates random delay in `[0, base^c - 1] * slot_time` | Config, C |
| `Truncated_Deterministic_Delay` | Deterministic delay with ceiling truncation | Config, C |
| `Truncated_Randomized_Delay` | Randomized delay with ceiling truncation | Config, C |

#### Expected Delay

| Function | Description | Parameters |
|----------|-------------|------------|
| `Expected_Delay` | Average expected delay for randomized BEB | Config, C |
| `Truncated_Expected_Delay` | Expected delay with ceiling truncation | Config, C |

#### State Management

| Procedure | Description | Parameters |
|-----------|-------------|------------|
| `Initialize_State` | Initialize backoff state to zero | State (out) |
| `Reset_State` | Reset backoff state to zero | State (in out) |
| `Increment_Collision` | Increment collision count and calculate new delay | State, Config, Use_Random |

#### Validation

| Procedure | Description | Parameters |
|-----------|-------------|------------|
| `Validate_Config` | Validate configuration parameters | Config |
| `Validate_Ceiling` | Validate ceiling value | Ceiling |

#### Helper Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `Power_Of_Two` | Calculate 2^c | C |
| `Clamp_Collision_Count` | Clamp collision count to ceiling | C, Ceiling |

### Exceptions

| Exception | Description |
|-----------|-------------|
| `Invalid_Config` | Raised when configuration is invalid |
| `Invalid_Collision_Count` | Raised when collision count is invalid |
| `Invalid_Ceiling` | Raised when ceiling value is invalid |

## Usage Examples

### Example 1: Basic Usage

```ada
with Ada.Text_IO; use Ada.Text_IO;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure Basic_Example is
   Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
   State  : Backoff_State;
begin
   Initialize_State (State);

   -- Simulate 5 collisions with deterministic truncated BEB
   for I in 1 .. 5 loop
      Increment_Collision (State, Config, Use_Random => False);
      Put_Line ("Collision" & Integer'Image (Integer(State.Collision_Count)) &
                ": Delay = " & Delay_Type'Image (State.Current_Delay) & " microseconds");
   end loop;
end Basic_Example;
```

### Example 2: Randomized Backoff

```ada
with Ada.Text_IO; use Ada.Text_IO;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure Randomized_Example is
   Config : Backoff_Config := (Base => 2, Ceiling => 5, Slot_Time => 1000);
   State  : Backoff_State;
begin
   Initialize_State (State);

   -- Simulate collisions with randomized delays
   for I in 1 .. 10 loop
      Increment_Collision (State, Config, Use_Random => True);
      Put_Line ("Attempt" & Integer'Image (I) & ": Waiting " &
                Delay_Type'Image (State.Current_Delay) & " ms before retry");
   end loop;
end Randomized_Example;
```

### Example 3: Direct Delay Calculation

```ada
with Ada.Text_IO; use Ada.Text_IO;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure Direct_Calculation is
   Config : Backoff_Config := Default_Config;
begin
   -- Calculate delays for different collision counts
   for C in 0 .. 15 loop
      Put_Line ("Collision " & Integer'Image (C) & ": " &
                "Deterministic = " & Delay_Type'Image (Deterministic_Delay (Config, C)) &
                ", Randomized max = " & Delay_Type'Image (Randomized_Delay (Config, C)));
   end loop;
end Direct_Calculation;
```

### Example 4: IEEE 802.3 Standard Compliance

```ada
with Ada.Text_IO; use Ada.Text_IO;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure IEEE_802_3_Example is
   -- IEEE 802.3 CSMA/CD standard configuration
   IEEE_Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
   State       : Backoff_State;
begin
   Initialize_State (State);

   Put_Line ("IEEE 802.3 CSMA/CD Backoff Simulation:");
   Put_Line ("Max delay: " & Delay_Type'Image (Truncated_Deterministic_Delay (IEEE_Config, 10)) & " microseconds");

   -- Simulate a collision scenario
   for Attempt in 1 .. 16 loop
      Increment_Collision (State, IEEE_Config, Use_Random => True);
      Put_Line ("Attempt " & Integer'Image (Attempt) & ": Backoff = " &
                Delay_Type'Image (State.Current_Delay) & " slot times");
   end loop;
end IEEE_802_3_Example;
```

## Testing

### Test Philosophy

The test suite verifies the correctness of the TBEB implementation by testing:

1. **Functional Correctness**: All delay calculation functions produce expected results
2. **Truncation Logic**: Delays are correctly capped at the ceiling value
3. **State Management**: State transitions work correctly
4. **Edge Cases**: Zero collisions, collisions above ceiling, invalid configurations
5. **Randomization**: Randomized delays stay within expected bounds
6. **Standard Compliance**: IEEE 802.3 standard behavior

### Test Execution

```bash
# Run all tests
make test

# Or compile and run manually
make
./bin/tests
```

### Test Output

Each test outputs `PASS` or `FAIL` for each assertion. All 47 tests should pass:

```
=== Truncated Binary Exponential Backoff Test Suite ===

TEST 1 - Deterministic Delay Calculation
  PASS: 1.1: Result for c=0 is slot_time
  PASS: 1.2: Result for c=1 is 2 * slot_time
  ...
=== All Tests Completed ===
```

## Mathematical Background

### Binary Exponential Backoff (BEB)

The basic BEB algorithm calculates the delay after `c` collisions as:

```
delay = base^c * slot_time
```

Where:
- `base` is typically 2 (binary exponential)
- `c` is the collision count
- `slot_time` is the time unit (e.g., 512 microseconds in Ethernet)

### Truncated BEB

To prevent unbounded growth, the collision count is clamped to a ceiling:

```
c_clamped = min(c, ceiling)
delay = base^c_clamped * slot_time
```

### Randomized BEB

To avoid synchronization, a random delay is chosen from the range:

```
delay = random(0, base^c - 1) * slot_time
```

### Expected Delay

The expected (average) delay for randomized BEB is:

```
expected_delay = (base^c - 1) / 2 * slot_time
```

## File Structure

```
.
├── truncated_binary_exponential_backoff.ads  # Package specification (types, functions)
├── truncated_binary_exponential_backoff.adb  # Package implementation
├── truncated_binary_exponential_backoff.gpr  # GNAT project file
├── tests.adb                                  # Comprehensive test suite (14 test groups)
├── Makefile                                  # Build configuration
├── obj/                                      # Compiled object files (generated)
└── bin/                                      # Executables (generated)
```

## Compilation Options

### Using Makefile (Recommended)

```bash
make clean    # Clean build artifacts
make          # Compile everything
make test     # Compile and run tests
```

### Using gnatmake Directly

```bash
# Compile the package
gnatmake -c truncated_binary_exponential_backoff.adb

# Compile and link a program
gnatmake my_program.adb -o bin/my_program
```

### Using gprbuild (Project File)

```bash
gprbuild -P truncated_binary_exponential_backoff.gpr
```

## Troubleshooting

### Common Issues

1. **"gnatmake: command not found"**
   - Install GNAT: `sudo apt-get install gnat` (Debian/Ubuntu)

2. **"libgnat-XX.so: cannot open shared object file"**
   - Install the matching runtime: `sudo apt-get install libgnat-XX`
   - Or recompile on your local machine

3. **Compilation errors**
   - Ensure you're using a recent version of GNAT (GCC 12+ recommended)
   - Run `make clean` before recompiling

### Getting Help

- Check the [GNAT User's Guide](https://docs.adacore.com/gnat_ugn-docs/html/gnat_ugn.html)
- Visit the [AdaCore forums](https://forums.adacore.com/)
- Review the [Ada Wikipedia](https://en.wikipedia.org/wiki/Ada_(programming_language))

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Feel free to use it in your projects.

## References

- [Wikipedia: Truncated Binary Exponential Backoff](https://en.wikipedia.org/wiki/Truncated_binary_exponential_backoff)
- [IEEE 802.3 CSMA/CD Standard](https://standards.ieee.org/standard/802_3-2024.html)
- [Ada Programming Language](https://en.wikipedia.org/wiki/Ada_(programming_language))
- [GNAT User's Guide](https://docs.adacore.com/gnat_ugn-docs/html/gnat_ugn.html)
