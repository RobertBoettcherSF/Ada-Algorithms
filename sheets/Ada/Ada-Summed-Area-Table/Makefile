.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb summed_area_table.ads summed_area_table.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	# Compile using GNAT project file to natively handle deps and output dirs
	gprbuild -P sat.gpr -p 

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	gprclean -P sat.gpr
	rm -rf $(OBJ_DIR) $(BIN_DIR)
