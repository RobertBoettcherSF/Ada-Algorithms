# Ada-Algorithms — build harness + per-algo test binaries (gnatmake).
GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022
OBJ_DIR := obj
BIN_DIR := bin

# Source search paths for packages + harness support units.
INCLUDES := -Isrc/sorting -Isrc/searching -Itests -Itests/sorting -Itests/searching

# Sheets built in place from their own folder (own flags, e.g. -gnata).
MODARITH := numerical/SPARK4/Ada-SPARK-Modular-Arithmetic

TEST_BINS := \
	$(BIN_DIR)/test_quicksort \
	$(BIN_DIR)/test_heapsort \
	$(BIN_DIR)/test_binary_search \
	$(BIN_DIR)/test_modular_arithmetic

HARNESS := $(BIN_DIR)/harness

.PHONY: all list test clean

all: $(HARNESS) $(TEST_BINS)

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

$(BIN_DIR)/test_quicksort: tests/sorting/test_quicksort.adb src/sorting/quicksort.ads src/sorting/quicksort.adb | $(BIN_DIR) $(OBJ_DIR)
	$(GNAT) $(FLAGS) $(INCLUDES) -D$(OBJ_DIR) -o $@ tests/sorting/test_quicksort.adb

$(BIN_DIR)/test_heapsort: tests/sorting/test_heapsort.adb src/sorting/heapsort.ads src/sorting/heapsort.adb | $(BIN_DIR) $(OBJ_DIR)
	$(GNAT) $(FLAGS) $(INCLUDES) -D$(OBJ_DIR) -o $@ tests/sorting/test_heapsort.adb

$(BIN_DIR)/test_binary_search: tests/searching/test_binary_search.adb src/searching/binary_search.ads src/searching/binary_search.adb | $(BIN_DIR) $(OBJ_DIR)
	$(GNAT) $(FLAGS) $(INCLUDES) -D$(OBJ_DIR) -o $@ tests/searching/test_binary_search.adb

$(BIN_DIR)/test_modular_arithmetic: $(wildcard $(MODARITH)/*.ads $(MODARITH)/*.adb) | $(BIN_DIR) $(OBJ_DIR)
	$(GNAT) $(FLAGS) -gnata -I$(MODARITH) -D$(OBJ_DIR) -o $@ $(MODARITH)/tests.adb

$(HARNESS): tests/harness.adb tests/categories.ads tests/categories.adb | $(BIN_DIR) $(OBJ_DIR)
	$(GNAT) $(FLAGS) $(INCLUDES) -D$(OBJ_DIR) -o $@ tests/harness.adb

list: $(HARNESS)
	@$(HARNESS) --list

# make test              → all
# make test CAT=sorting  → one category
test: all
ifeq ($(CAT),)
	@$(HARNESS) --all
else
	@$(HARNESS) --category $(CAT)
endif

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
