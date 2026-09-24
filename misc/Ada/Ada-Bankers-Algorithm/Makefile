#  Makefile for Banker's Algorithm Ada Project
#
#  This Makefile provides targets for compiling and running the Banker's Algorithm
#  implementation and its test suite.
#
#  Author: Vibe Code (Mistral AI)
#  Date: 2024

.PHONY: all test clean compile

#  Compiler
GNAT = gnatmake

#  Directories
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = .

#  Source files
ADS_FILES = bankers_algorithm.ads
ADB_FILES = bankers_algorithm.adb
TEST_FILES = tests.adb

#  Executables
MAIN_EXE = $(BIN_DIR)/bankers_algorithm
TEST_EXE = $(BIN_DIR)/tests

#  Compiler flags
GNAT_FLAGS = -g -gnatN -gnata
#  -g: Include debug information
#  -gnatN: Enable assertions
#  -gnata: Enable static analysis

all: $(MAIN_EXE) $(TEST_EXE)

#  Compile the main package
$(MAIN_EXE): $(ADS_FILES) $(ADB_FILES)
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNAT_FLAGS) -o $(MAIN_EXE) $(ADS_FILES) $(ADB_FILES)

#  Compile the test suite
$(TEST_EXE): $(ADS_FILES) $(ADB_FILES) $(TEST_FILES)
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNAT_FLAGS) -o $(TEST_EXE) $(TEST_FILES)

#  Run tests
test: $(TEST_EXE)
	@echo "Running Banker's Algorithm test suite..."
	@echo "========================================"
	@$(TEST_EXE)

#  Compile everything
compile: $(MAIN_EXE) $(TEST_EXE)

#  Clean up
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

#  Rebuild everything
rebuild: clean all

#  Show help
help:
	@echo "Banker's Algorithm Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build all executables"
	@echo "  test     - Run the test suite"
	@echo "  compile  - Compile all source files"
	@echo "  clean    - Remove all object and executable files"
	@echo "  rebuild  - Clean and rebuild everything"
	@echo "  help     - Show this help message"
