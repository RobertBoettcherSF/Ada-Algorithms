# Makefile for Fair-Share Scheduler

all: clean build run

build: main_demo tests

main_demo: main.adb fair_share_scheduler.adb fair_share_scheduler.ads
	mkdir -p obj
	gprbuild -P fair_share.gpr

tests: tests.adb fair_share_scheduler.adb fair_share_scheduler.ads
	mkdir -p obj
	gprbuild -P tests.gpr

run: main_demo
	./main

test: tests
	./tests

clean:
	rm -rf obj *.o *.ali *.exe main tests

.PHONY: all build run test clean
