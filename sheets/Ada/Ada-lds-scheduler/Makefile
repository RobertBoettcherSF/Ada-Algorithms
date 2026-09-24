all: build run

build:
	mkdir -p obj
	gprbuild -P lst_scheduler.gpr

run: build
	./obj/main

clean:
	rm -rf obj

.PHONY: all build run clean
