# Makefile
.PHONY: all test clean build

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: build

build: main.adb tests.adb adaptive_huffman.adb adaptive_huffman.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P adaptive_huffman.gpr

test: build
	@echo "\n======================"
	@echo "Running tests..."
	@echo "======================"
	./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
