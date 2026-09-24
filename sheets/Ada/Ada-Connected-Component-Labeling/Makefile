.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb connected_components.adb connected_components.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P ccl.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
