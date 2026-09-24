GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022
OBJ_DIR := obj
BIN_DIR := bin

.PHONY: all test prove clean

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -Pknuth_bendix_completion.gpr

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

prove:
	mkdir -p $(OBJ_DIR)
	gnatprove -Pknuth_bendix_completion.gpr --level=2 --timeout=60 -j0

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) gnatprove
