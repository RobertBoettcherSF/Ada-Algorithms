.PHONY: all test clean

GNAT = gnatmake
GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: image_segmentation.ads image_segmentation.adb main.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -Pimage_segmentation.gpr main.adb

$(BIN_DIR)/tests: image_segmentation.ads image_segmentation.adb tests.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -Pimage_segmentation.gpr tests.adb

test: $(BIN_DIR)/tests
	@echo "Running verification test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
