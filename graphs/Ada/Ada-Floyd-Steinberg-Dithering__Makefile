# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb floyd_steinberg.adb floyd_steinberg.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P floyd_steinberg.gpr -p

test: $(BIN_DIR)/tests
	@echo "Executing Verification Suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
