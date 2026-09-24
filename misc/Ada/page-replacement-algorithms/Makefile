# Makefile for Ada Page Replacement Algorithms

# Compiler
GNATMAKE = gnatmake

# Project file
PROJECT = page_replacement.gpr

# Directories
SRC_DIR = .
OBJ_DIR = obj
BIN_DIR = bin

# Main executable
MAIN = test_page_replacement

.PHONY: all build run clean

all: build

build: 
	$(GNATMAKE) -P $(PROJECT)

run: build
	./$(BIN_DIR)/$(MAIN)

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/$(MAIN)

.PHONY: rebuild
rebuild: clean build
