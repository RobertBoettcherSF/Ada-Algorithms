.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb fictitious_play.adb fictitious_play.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P fictitious_play.gpr

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
