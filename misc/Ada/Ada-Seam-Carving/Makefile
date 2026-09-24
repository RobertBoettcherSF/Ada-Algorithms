.PHONY: all test clean

GNAT = gnatmake
GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb seam_carving.ads seam_carving.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P seam_carving.gpr main.adb

$(BIN_DIR)/tests: tests.adb seam_carving.ads seam_carving.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P seam_carving.gpr tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
