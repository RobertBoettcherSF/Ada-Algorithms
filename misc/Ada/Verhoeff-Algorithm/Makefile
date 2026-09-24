.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb verhoeff.adb verhoeff.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P verhoeff.gpr

test: all
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
