.PHONY: all test clean

GNAT = gnatmake
# -gnata enables pragma Assert verification routines
GNATFLAGS = -gnata
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb ricart_agrawala.ads ricart_agrawala.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNATFLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb ricart_agrawala.ads ricart_agrawala.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNATFLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
