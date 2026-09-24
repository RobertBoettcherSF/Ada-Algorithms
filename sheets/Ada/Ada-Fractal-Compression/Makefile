.PHONY: all test clean

all:
	mkdir -p obj bin
	gprbuild -P fractal.gpr

bin/tests: tests.adb fractal_compression.adb fractal_compression.ads
	mkdir -p obj bin
	gprbuild -P fractal.gpr

test: bin/tests
	@echo "Running Verification & Validation test suite..."
	@./bin/tests

clean:
	gprclean -P fractal.gpr || true
	rm -rf obj bin
