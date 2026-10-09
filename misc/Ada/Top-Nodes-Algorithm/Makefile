# Makefile for Ada Top Nodes Algorithm

.PHONY: all build test clean rebuild

all: build test

build: obj/top_nodes_algorithm.ali

obj/top_nodes_algorithm.ali: top_nodes_algorithm.ads top_nodes_algorithm.adb
	mkdir -p obj
	gprbuild -P top_nodes.gpr

obj/test_top_nodes: test_top_nodes.adb test_reference.adb obj/top_nodes_algorithm.ali
	mkdir -p obj
	gprbuild -P test_project.gpr

test: obj/test_top_nodes
	./obj/test_top_nodes
	./obj/test_reference

clean:
	rm -rf obj

rebuild: clean build test
