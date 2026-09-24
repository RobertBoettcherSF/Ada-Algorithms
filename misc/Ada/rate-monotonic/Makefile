# ============================================================================
# Rate Monotonic Scheduling - Makefile
# ============================================================================
# This Makefile provides targets for building and testing the Rate_Monotonic
# Ada package.
#
# Targets:
#   all       - Build everything
#   compile   - Compile the Rate_Monotonic library
#   tests     - Compile and run the test suite
#   clean     - Clean up build artifacts
#   run       - Run the test suite (after compilation)
# ============================================================================

# Configuration
GPRBUILD ?= gprbuild
GNATMAKE ?= gnatmake

# Directories
SRC_DIR = .
TEST_DIR = tests
OBJ_DIR = $(TEST_DIR)/obj
BIN_DIR = $(TEST_DIR)/bin

.PHONY: all compile tests clean run

all: compile tests

compile:
	@echo "Compiling Rate_Monotonic library..."
	@mkdir -p $(OBJ_DIR)
	cd $(SRC_DIR) && $(GPRBUILD) -P rate_monotonic.gpr 2>&1 | grep -v "^  " | grep -v "^$$" || true

tests: compile
	@echo "Compiling test suite..."
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	cd $(TEST_DIR) && $(GPRBUILD) -P tests.gpr 2>&1 | grep -v "^  " | grep -v "^$$" || true

run: tests
	@echo "Running test suite..."
	cd $(TEST_DIR) && ./bin/rate_monotonic_tests

clean:
	@echo "Cleaning build artifacts..."
	-rm -rf $(OBJ_DIR)
	-rm -rf $(BIN_DIR)
	-rm -rf obj
	find . -name "*.o" -delete
	find . -name "*.ali" -delete
	find . -name "*.bexch" -delete

# Help target
.PHONY: help
help:
	@echo "Rate Monotonic Scheduling - Makefile Help"
	@echo "=========================================="
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build everything"
	@echo "  compile   - Compile the Rate_Monotonic library"
	@echo "  tests     - Compile and run the test suite"
	@echo "  clean     - Clean up build artifacts"
	@echo "  run       - Run the test suite (after compilation)"
	@echo "  help      - Show this help message"
	@echo ""
