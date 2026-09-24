# Makefile for Ada Top Nodes Algorithm

# Default target
all: build test

# Build the library
build: obj/top_nodes_algorithm.ali

# Build the tests
test: obj/test_top_nodes

# Run the tests
run: test
	./obj/test_top_nodes

# Clean up
clean:
	rm -rf obj

# Build everything from scratch
rebuild: clean build test

# Individual targets
obj/top_nodes_algorithm.ali: top_nodes_algorithm.ads top_nodes_algorithm.adb
	mkdir -p obj
	gprbuild -P top_nodes.gpr

obj/test_top_nodes: test_top_nodes.adb obj/top_nodes_algorithm.ali
	mkdir -p obj
	gprbuild -P test_project.gpr

# Phony targets
.PHONY: all build test run clean rebuild
