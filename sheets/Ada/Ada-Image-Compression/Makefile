.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb image_compression.ads image_compression.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	# Compile using the GNAT project file to ensure assertions and flags are handled natively
	$(GNAT) -P image_compression.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
