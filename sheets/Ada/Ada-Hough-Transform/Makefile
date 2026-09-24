# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
# Include -gnata to enable pragmas (assertions) during compilation
GNATFLAGS = -gnata -g -O2 -D $(OBJ_DIR)

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb hough_transform.adb hough_transform.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNATFLAGS) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb hough_transform.adb hough_transform.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNATFLAGS) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
