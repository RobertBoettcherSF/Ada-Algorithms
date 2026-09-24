GNAT    := gnatmake
SPARK   := gnatprove
FLAGS   := -gnatwa -gnat2022 -gnata
OBJ_DIR := obj
BIN_DIR := bin

.PHONY: all test clean prove

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -Psort_merge_join.gpr

prove: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR)
	$(SPARK) -Psort_merge_join.gpr --level=4

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
