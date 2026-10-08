.PHONY: all test clean

GNAT = gnatmake
GNAT_FLAGS = -gnatwa -gnat2022 -gnata
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb lulea_algorithm.ads lulea_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNAT_FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
