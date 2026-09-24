# Makefile
.PHONY: all test clean

GNAT = gnatmake
GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb video_compression.adb video_compression.ads
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P video_compression.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
