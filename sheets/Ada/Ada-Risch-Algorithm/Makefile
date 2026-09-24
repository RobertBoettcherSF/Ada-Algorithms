.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb risch_algorithm.adb risch_algorithm.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR); \
	$(GNAT) -P risch.gpr

test: all
	@echo "==========================================="
	@echo "  Running Risch Algorithm V&V Test Suite"
	@echo "==========================================="
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
