## Project Overview

This project implements three distinct, classic variants of the **Operator-Precedence Parser**, a category of bottom-up and top-down parsers designed to interpret arithmetic operator-precedence grammars efficiently. The project is implemented strictly in Ada 2023, exhibiting safe bounded evaluation structures over three independent algorithmic strategies.

---

## Features

- **Variant 1: Table-Driven Shift-Reduce Evaluator**
  - Classic bottom-up parsing using a 2D precedence relation matrix (`Yields`, `Takes`, `Accepts`).
- **Variant 2: Pratt Parser (Top-Down Operator Precedence)**
  - Uses recursive descent mapping Left Binding Power (LBP) dynamically.
- **Variant 3: Dijkstra's Shunting-Yard Algorithm**
  - Translates mathematically grouped infix tokens to Reverse Polish Notation (Postfix), alongside an evaluation helper function.
- **Strongly Typed and Assured:** No dynamic allocations or access types; heavily annotated with Ada 2023 `Pre` conditions and memory-bounded stacks.

---

## Usage

Ensure you have the GNAT compilation tools installed. The build logic is wrapped inside a standard Makefile format leveraging `gnatmake`.

To compile and verify all systems interactively, simply run:

```bash
make test
```

**Expected Output:**  
You will see consecutive output streams testing structural correctness, error handling for division by zero and faulty syntax schemas, evaluating up to 42 active assertions yielding 0 failed.

---

## Testing

The standalone main runner (`tests.adb`) utilizes a bespoke lexer string-to-token framework. It inherently guarantees correctness across all three algorithm variations running dynamically parallel over identical inputs.

**Categories validated include:**

- Precedence priorities &amp; left associativity overrides.
- Edge cases (e.g., valid empty numeric singletons like `"42"` vs syntax-banned trailing operators).
- Complete state-machine reset checks (ensuring robust stack closure logic).

---

## Building

**Prerequisites:** GNAT Toolchain configured with Ada 2022/2023 language features.

Project defaults append `-gnatwa` ensuring mathematically pristine, zero-warning compilation.
