#  Version: 0.001
#  Ada-SPARK-Modular-Arithmetic -- make + GNAT only.
#    make test               build and run the tests (GNAT 14 by default)
#    make test GNAT=gnatmake-12
#    make prove              gnatprove --level=4 on the whole sheet
#    make mutate             deliberate-break mutation pass (tools/mutate.adb)

GNAT    ?= gnatmake
SPARK   ?= gnatprove
FLAGS   := -gnatwa -gnat2022 -gnata
OBJ_DIR := obj/$(notdir $(GNAT))
BIN_DIR := bin

.PHONY: all test prove mutate clean

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -q $(FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

prove:
	$(SPARK) -Pmodular_arithmetic.gpr --level=4 -j0

$(BIN_DIR)/mutate: tools/mutate.adb
	mkdir -p $(OBJ_DIR)/tools $(BIN_DIR)
	$(GNAT) -q -gnatwa -gnat2022 -D $(OBJ_DIR)/tools -o $(BIN_DIR)/mutate tools/mutate.adb

mutate: $(BIN_DIR)/mutate
	$(BIN_DIR)/mutate --gnatmake=$(GNAT)

clean:
	rm -rf obj $(BIN_DIR) mutate_work
