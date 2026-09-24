# Ada Rate-Monotonic Scheduling

A comprehensive Ada implementation of **Rate-Monotonic Scheduling (RMS)** - a static-priority scheduling algorithm for real-time systems, with a complete test suite.

## 📋 Overview

Rate-Monotonic Scheduling (RMS) is a fundamental real-time scheduling algorithm where **shorter period = higher priority**. This implementation provides:

- **Priority Assignment**: Automatic static priority assignment based on task periods
- **ISR Mitigation**: Correction of mis-prioritized Interrupt Service Routines
- **Schedulability Tests**: Multiple theoretical bounds to verify task set schedulability
- **Resource Sharing**: Priority Ceiling Protocol via Ada protected objects

## 🏗️ Project Structure

```
Ada-rate-monotonic/
├── rate_monotonic.ads          # Package specification (API)
├── rate_monotonic.adb          # Package implementation
├── rate_monotonic.gpr          # GPR project file
├── tests/
│   ├── rate_monotonic_tests.adb  # Comprehensive test suite (50 tests)
│   └── tests.gpr                 # Test project file
├── run_tests.sh                # Shell script to run tests
├── Makefile                    # Makefile for building/testing
└── README.md                    # This file
```

## 📚 Theory Background

### Rate-Monotonic Principle

In RMS, tasks are assigned **static priorities** based on their **periods**:
- **Shorter period = Higher priority**
- Priorities are fixed at design time (not dynamic)
- Optimal for periodic real-time tasks with deadlines equal to periods

### Schedulability Tests

This implementation includes multiple theoretical bounds:

| Test | Bound | Description |
|------|-------|-------------|
| **Liu & Layland** | U ≤ n(2^(1/n) - 1) | Classic RMS bound (1973) |
| **Hyperbolic** | ∏(U_i + 1) ≤ 2 | Tighter bound by Bini et al. |
| **Harmonic** | U ≤ 1.0 | For harmonic task sets (periods are integer multiples) |
| **Harmonic Chains** | U ≤ K(2^(1/K) - 1) | Generalized bound by Kuo & Mok |
| **Stochastic** | U ≤ 0.88 | Empirical bound for random task sets |

Where **U** = Total utilization = Σ(C_i / T_i)

## 🚀 Quick Start

### Prerequisites

- **GNAT (GNU Ada Compiler)** - Version 12 recommended
- **GPRbuild** (optional, but recommended)

#### Install on Ubuntu/Debian:
```bash
sudo apt-get install gnat gprbuild libgnat-12 libgnarl-12
```

#### Install on Fedora:
```bash
sudo dnf install gcc-gnat gprbuild
```

#### Install on macOS (Homebrew):
```bash
brew install gnat
```

### Running the Tests

The easiest way to verify everything works:

```bash
# Clone the repository
git clone https://github.com/RobertBoettcherSF/Ada-rate-monotonic.git
cd Ada-rate-monotonic

# Run all tests
./run_tests.sh
```

**Expected output:**
```
Test Summary:
  Total Tests:   50
  Passed:        50
  Failed:        0
  Success Rate:  100%
All tests PASSED!
```

### Alternative Methods

```bash
# Using make
make tests

# Or manually
cd tests
gprbuild -P tests.gpr
./bin/rate_monotonic_tests
```

## 🧪 Test Suite

The test suite contains **50 comprehensive tests** across **10 test suites**:

### 📊 Test Suite Breakdown

| Suite | Tests | Description |
|-------|-------|-------------|
| **1. Priority Assignment** | 6 | Verifies task sorting by period and priority assignment |
| **2. ISR Mitigation** | 4 | Tests ISR period capping to shortest non-ISR period |
| **3. Utilization Calculation** | 4 | Tests utilization computation (0%, 50%, 100%, >100%) |
| **4. Liu & Layland** | 4 | Tests the classic RMS schedulability bound |
| **5. Hyperbolic Bound** | 4 | Tests Bini et al.'s tighter bound |
| **6. Harmonic Task Set** | 4 | Tests harmonic period detection |
| **7. Harmonic Chains** | 3 | Tests Kuo & Mok's generalized bound |
| **8. Stochastic** | 4 | Tests the 0.88 empirical bound |
| **9. Edge Cases** | 5 | Tests boundary conditions and special cases |
| **10. Integration** | 2 | Tests complete workflows |

### 🎯 Test Design Philosophy

All tests follow three key principles:

1. **Explicit Assumptions**: Each test clearly states what behavior it expects
2. **Diverse Scenarios**: Tests cover normal cases, edge cases, and boundary conditions
3. **Falsifiable**: Tests will **fail** if the implementation is incorrect, proving assumptions false

This ensures the implementation is **robust, correct, and maintainable**.

### 📝 Test Examples

```ada
-- Test: Verify priority assignment
Tasks : Task_Array := (
   1 => Make_Task(1, 1.0, 10.0),
   2 => Make_Task(2, 2.0, 5.0),
   3 => Make_Task(3, 0.5, 2.0)
);
Assign_Priorities (Tasks);
-- Assert: Shortest period (2.0) gets highest priority (3)
Assert_Equal (Tasks(1).Priority, 3, "Shortest period gets highest priority");
```

## 💡 Usage Examples

### Basic Usage

```ada
with Rate_Monotonic;

procedure Example is
   use Rate_Monotonic;
   
   -- Define a task set
   Tasks : Task_Array := (
      1 => (Id => 1, Computation_Time => 1.0, Period => 10.0),
      2 => (Id => 2, Computation_Time => 2.0, Period => 20.0),
      3 => (Id => 3, Computation_Time => 0.5, Period => 5.0, Is_ISR => True)
   );
   
   -- Assign priorities (shorter period = higher priority)
   Assign_Priorities (Tasks);
   
   -- Mitigate ISR priority issues
   Mitigate_ISRs (Tasks);
   
   -- Calculate total utilization
   declare
      U : Float := Calculate_Utilization (Tasks);
   begin
      Put_Line ("Utilization: " & Float'Image(U));
   end;
   
   -- Check schedulability
   if Is_Schedulable_Liu_Layland (Tasks) then
      Put_Line ("Task set is schedulable by Liu & Layland bound");
   end if;
   
end Example;
```

### Using the Helper Function

For cleaner code, use the `Make_Task` helper:

```ada
Tasks : Task_Array := (
   1 => Make_Task(1, 1.0, 10.0),
   2 => Make_Task(2, 0.5, 20.0, Is_ISR => True)
);
```

### Resource Sharing with Priority Ceiling

```ada
-- Create a shared resource with priority ceiling
Resource : Shared_Resource (System.Priority'(10));

-- In a task:
Resource.Lock;  -- Priority instantly elevated to ceiling
-- Critical section
Resource.Unlock;
```

## 🔧 API Reference

### Types

```ada
-- Task record with default values
type Task_Record is record
   Id               : Natural;
   Computation_Time : Float;  -- Worst-case execution time (C_i)
   Period           : Float;  -- Period/Deadline (T_i)
   Is_ISR           : Boolean := False;
   Priority         : Natural := 0;
end record;

type Task_Array is array (Positive range <>) of Task_Record;
```

### Priority Assignment

```ada
-- Sort tasks by period (shortest first) and assign priorities
procedure Assign_Priorities (Tasks : in out Task_Array);
```

### ISR Mitigation

```ada
-- Cap ISR periods to shortest non-ISR period
procedure Mitigate_ISRs (Tasks : in out Task_Array);
```

### Utilization

```ada
-- Calculate total utilization: U = Σ(C_i / T_i)
function Calculate_Utilization (Tasks : Task_Array) return Float;
```

### Schedulability Tests

```ada
-- Liu & Layland bound: U ≤ n(2^(1/n) - 1)
function Is_Schedulable_Liu_Layland (Tasks : Task_Array) return Boolean;

-- Hyperbolic bound: ∏(U_i + 1) ≤ 2
function Is_Schedulable_Hyperbolic (Tasks : Task_Array) return Boolean;

-- Harmonic task set detection
function Is_Harmonic_Task_Set (Tasks : Task_Array) return Boolean;

-- Harmonic chains bound
function Is_Schedulable_Harmonic_Chains (Tasks : Task_Array) return Boolean;

-- Stochastic bound: U ≤ 0.88
function Is_Schedulable_Stochastic (Tasks : Task_Array) return Boolean;
```

### Resource Sharing

```ada
-- Protected resource with priority ceiling
protected type Shared_Resource (Ceiling_Priority : System.Priority) is
   pragma Priority (Ceiling_Priority);
   entry Lock;
   procedure Unlock;
private
   Is_Locked : Boolean := False;
end Shared_Resource;
```

## 📖 Background: Rate-Monotonic Scheduling

### Historical Context

- **1973**: Liu & Layland proved RMS is optimal for periodic tasks with deadlines ≤ periods
- **1980s**: Extensions for harmonic task sets, ISR handling
- **1990s**: Tighter bounds (Hyperbolic, Harmonic Chains)
- **2000s**: Empirical studies showed 0.88 bound for random task sets

### When to Use RMS

✅ **Good for:**
- Periodic real-time tasks
- Static priority systems
- Tasks with deadlines equal to periods
- Systems where shorter period = more critical

❌ **Not ideal for:**
- Aperiodic tasks
- Dynamic priority systems
- Tasks with deadlines < periods (use EDF instead)
- Systems with complex dependencies

### Comparison with Other Algorithms

| Algorithm | Priority | Dynamic? | Optimality |
|-----------|----------|----------|-------------|
| **RMS** | Period-based | No | Optimal for periodic tasks |
| **EDF** | Deadline-based | Yes | Optimal for arbitrary deadlines |
| **DM** | Deadline-based | No | Optimal for constrained deadlines |
| **FIFO** | Arrival order | No | Not optimal |

## 🛠️ Building & Compilation

### Compile the Library

```bash
# Using gprbuild
gprbuild -P rate_monotonic.gpr

# Using make
make compile
```

### Compile Tests

```bash
# Using make
make tests

# Or manually
cd tests
gprbuild -P tests.gpr
```

### Clean Build

```bash
make clean
```

## 🐛 Troubleshooting

### "exec directory 'bin' not found" error

**Solution:** The build scripts create directories automatically. If you see this:
```bash
mkdir -p tests/obj tests/bin obj
./run_tests.sh
```

### "no value supplied for component Priority" error

**Solution:** Use named notation for task records:
```ada
-- Correct:
Tasks : Task_Array := (
   1 => Make_Task(1, 1.0, 10.0)
);

-- Or with explicit fields:
Tasks : Task_Array := (
   1 => (Id => 1, Computation_Time => 1.0, Period => 10.0, Is_ISR => False, Priority => 0)
);
```

### "reserved word 'task' cannot be used as identifier" error

**Solution:** Don't use `Task` as a function name. Use `Make_Task` instead:
```ada
-- Correct:
function Make_Task (...) return Task_Record

-- Incorrect:
function Task (...) return Task_Record  -- 'task' is reserved
```

### Linker errors (missing -lgnarl-12, -lgnat-12)

**Solution:** Install the Ada runtime libraries:
```bash
# Ubuntu/Debian
sudo apt-get install libgnat-12 libgnarl-12

# Fedora
sudo dnf install gcc-gnat
```

## 📜 License

This project is open source. See the repository for licensing details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the test suite (`./run_tests.sh`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📞 Support

For issues or questions:
- Check the [GitHub Issues](https://github.com/RobertBoettcherSF/Ada-rate-monotonic/issues)
- Review the test suite for usage examples
- Consult the Ada documentation for GNAT-specific questions

## 🎯 Version History

| Version | Date | Changes |
|---------|------|---------|
| **1.2** | 2024-07-16 | Eliminated all compiler warnings, fixed all tests |
| **1.1** | 2024-07-16 | Fixed compilation issues, added directory placeholders |
| **1.0** | 2024-07-16 | Initial release with 50 comprehensive tests |

---

**✨ Clean, tested, production-ready Rate-Monotonic Scheduling for Ada!**
