GNATFLAGS = -gnatwa -gnat2022 -gnata -g -O0
SRC = src
TEST = tests
OBJ = obj

.PHONY: all test prove clean

all: test

$(OBJ):
	mkdir -p $(OBJ)

test: $(OBJ)
	gnatmake $(GNATFLAGS) -D $(OBJ) -I$(SRC) -o $(OBJ)/test_mission_fsm \
	  $(TEST)/test_mission_fsm.adb
	$(OBJ)/test_mission_fsm

prove:
	@command -v gnatprove >/dev/null || { echo "gnatprove not found"; exit 1; }
	gnatprove -P mission_fsm.gpr --level=2 --timeout=30 --report=all

clean:
	rm -rf $(OBJ) gnatprove auto.cgpr *.ali *.o
