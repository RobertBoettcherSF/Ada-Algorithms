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

.PHONY: all list test clean proof-index vv vv-validate check-paths

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

# Regenerate PROOFS.md / PROOFS.csv and the headline block in README.md (between the
# proof-index markers; idempotent) via tools/vv/run_proof_index.py (H188).
#   make proof-index                 inputs synthesised from the committed PROOFS.csv (default)
#   make proof-index RESULTS=/path/with/build.jsonl+prove.jsonl PROVE_LOGS=$TMPDIR/aa_prove \
#                    STEPS_LOGS=$TMPDIR/aa2s TOOL_INFO=toolinfo.txt [ALLOW_INPUT_CHANGE=1]
#     a new build + prove run (see tools/audit/README.md); fails (exit 2, files restored) when its
#     inputs differ from the committed PROOFS.csv unless ALLOW_INPUT_CHANGE=1; always fails (exit 3)
#     when the index and tools/vv/recount_strict.py disagree on training-ready / rescore_pending.
VV_TMP     := $(shell dirname "$$(mktemp -u)")
RESULTS    ?=
PROVE_LOGS ?= $(if $(RESULTS),$(VV_TMP)/aa_prove)
ALLOW_INPUT_CHANGE ?=
STEPS_LOGS ?=
TOOL_INFO  ?=
STEPS      ?= 1000000
proof-index:
	python3 tools/vv/run_proof_index.py $(if $(RESULTS),--results $(RESULTS) --logs $(PROVE_LOGS)) \
	  $(if $(ALLOW_INPUT_CHANGE),--allow-input-change) -- \
	  $(if $(STEPS_LOGS),--steps-logs $(STEPS_LOGS)) $(if $(TOOL_INFO),--tool-info $(TOOL_INFO)) \
	  $(if $(RESULTS),--steps-cmd "gnatprove -P <folder gpr> --mode=silver --level=2 --timeout=0 --steps=$(STEPS) --counterexamples=off -j2 --output=oneline -k")

# Tracked files must not name absolute box paths (scratch dirs, other worktrees, home);
# allowlist with written reasons in tools/vv/check_paths_allow.csv.
check-paths:
	python3 tools/vv/check_paths.py
	python3 tools/vv/check_placeholders.py
	python3 tools/vv/check_unrun_tests.py

# Verification + validation over all folders (docs/VV.md): build+tests on GNAT 14/12,
# Silver proofs with a step budget, differential + mutation testing, index refresh.
#   make vv                         full run (hours)
#   make vv VV_IDS=ids.txt          a subset;  VV_SKIP="build prove" to run validation only
vv:
	tools/vv/run_vv.sh

# Validation only (differential tests + mutation sample), then refresh the index from existing results.
vv-validate:
	VV_SKIP="build prove" VV_OUT=$(or $(RESULTS),$(VV_TMP)/aa_res) VV_PROVE_LOGS=$(or $(PROVE_LOGS),$(VV_TMP)/aa_prove) tools/vv/run_vv.sh
