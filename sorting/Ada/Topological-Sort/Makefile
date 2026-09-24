.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb topological_sorting.adb topological_sorting.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR) ; \
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running verification and validation tests..." ; \
	./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
