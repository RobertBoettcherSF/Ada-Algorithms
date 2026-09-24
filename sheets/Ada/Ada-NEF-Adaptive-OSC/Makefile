# Ada-NEF-Adaptive-OSC — no Alire; plain gnatmake
ADAFLAGS := -gnatwa -gnat2022 -gnata
SRC      := src
OBJ      := obj
BIN      := bin

.PHONY: all test clean

all: test

test: $(BIN)/tests
	@$(BIN)/tests

$(BIN)/tests: tests.adb \
    $(SRC)/osc_pd.ads $(SRC)/osc_pd.adb \
    $(SRC)/adaptive_residual.ads $(SRC)/adaptive_residual.adb \
    $(SRC)/plant_sim.ads $(SRC)/plant_sim.adb
	mkdir -p $(OBJ) $(BIN)
	gnatmake $(ADAFLAGS) -D $(OBJ) -o $(BIN)/tests tests.adb \
	  -I$(SRC) -bargs -shared -largs

clean:
	rm -rf $(OBJ) $(BIN)
