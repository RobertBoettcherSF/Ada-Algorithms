# Makefile for Ada Clock Replacement Algorithms
# Uses GNAT (GNU Ada Compiler)

# Compiler settings
GNAT := gnatmake
GPRBUILD := gprbuild
GPR_FILE := clock_variants.gpr

# Directories
SRC_DIR := .
OBJ_DIR := obj
BIN_DIR := bin
TEST_DIR := tests

# Source files
SRC_FILES := clock_algorithms.ads clock_algorithms.adb
TEST_FILES := run_tests.adb tests/clock_tests.ads tests/clock_tests.adb

# Compiler flags
GNAT_FLAGS := -g -O2 -gnat12 -gnata

# Default target
all: library

# Build the library
library: $(SRC_FILES)
	@mkdir -p $(OBJ_DIR)
	$(GNAT) -P $(GPR_FILE) $(GNAT_FLAGS)

# Build and run tests
tests: $(TEST_FILES)
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) run_tests.adb $(GNAT_FLAGS)
	./obj/run_tests

# Build test library only
testlib: $(TEST_FILES)
	@mkdir -p $(OBJ_DIR)
	$(GNAT) -P $(GPR_FILE) $(GNAT_FLAGS)

# Build and run a simple test program
test: test_clock.adb
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) test_clock.adb $(GNAT_FLAGS)
	./obj/test_clock

# Clean build artifacts
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) *.o *.ali *.exe

# Clean everything
clobber: clean
	rm -f test_clock run_tests

# Show available targets
help:
	@echo "Available targets:"
	@echo "  all      - Build the library (default)"
	@echo "  library  - Build the library"
	@echo "  tests    - Build and run all tests (15 tests)"
	@echo "  test     - Build and run simple test program"
	@echo "  testlib  - Build test library only"
	@echo "  clean    - Remove build artifacts"
	@echo "  clobber  - Remove all build files"
	@echo ""
	@echo "Note: Executables are built in obj/ directory"

.PHONY: all library tests test testlib clean clobber help
