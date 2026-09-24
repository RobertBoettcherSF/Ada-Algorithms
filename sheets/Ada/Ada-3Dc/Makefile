.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: test

$(BIN_DIR)/tests: tests.adb three_dc.adb three_dc.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P three_dc.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
