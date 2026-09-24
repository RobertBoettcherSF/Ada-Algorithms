# Ada-NEF-Neurorobotics-Core — no Alire; plain gnatmake
ADAFLAGS := -gnatwa -gnat2022 -gnata
SRC      := src
OBJ      := obj
BIN      := bin

.PHONY: all test clean

all: test

test: $(BIN)/tests
	@$(BIN)/tests

$(BIN)/tests: tests.adb \
    $(SRC)/rover_control.ads $(SRC)/rover_control.adb \
    $(SRC)/lif_neuron.ads $(SRC)/lif_neuron.adb \
    $(SRC)/nef_ensemble.ads $(SRC)/nef_ensemble.adb
	mkdir -p $(OBJ) $(BIN)
	gnatmake $(ADAFLAGS) -D $(OBJ) -o $(BIN)/tests tests.adb \
	  -I$(SRC) -bargs -shared -largs

clean:
	rm -rf $(OBJ) $(BIN)
