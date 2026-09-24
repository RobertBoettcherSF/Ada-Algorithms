# Zeller's Congruence in Ada

## Project Overview
This codebase implements [Zeller's congruence](https://en.wikipedia.org/wiki/Zeller%27s_congruence), a mathematical algorithm devised by Christian Zeller to calculate the day of the week for any Julian or Gregorian calendar date. The implementation uses strict Ada typing and logic bounds to achieve highly reliable chronological conversions.

## Features
- **Gregorian Calendar Variant**: Standard date calculation for the modern calendar.
- **Julian Calendar Variant**: Calculations for historical dates pre-dating the Gregorian shift.
- **ISO 8601 Variant**: Both calendar variants feature a wrapper mapping standard Zeller outputs (0=Sat .. 6=Fri) to standard ISO-8601 enumeration (1=Mon .. 7=Sun).
- **Date Validation Engine**: Helper mechanisms to block impossible mathematical scenarios like "February 29, 1900" (Gregorian) while appropriately allowing them in the Julian context.

## Testing 
Strict Verification & Validation (V&V) methodologies were utilized, assuming fundamentally pessimistic hypotheses about system behavior. The test suite contains 14 rigorous, terminal-executable tests that assert failure modes, boundary limits, and algorithmic validity. **A test PASS means the assumption that the code is broken has been mathematically disproved.**

### Test Categories
1. **Functional Correctness (T1-T10, T13)** 
   - *What it verifies:* Calculates known historical (e.g., Battle of Hastings) and future temporal anchor points.
   - *Why it matters:* Proves the mathematical transcription of the formula (Verification) performs safely in reality (Validation).
2. **Error Handling (T11-T12)** 
   - *What it verifies:* Ensures erroneous inputs (e.g. April 31st, non-leap year Feb 29) are gracefully trapped via exceptions.
   - *Why it matters:* Prevents cascading logic failures downstream in critical systems relying on accurate temporal data.
3. **Edge Cases & Robustness (T4, T8, T14)** 
   - *What it verifies:* Validates boundary transitions (e.g., end of February into March), requiring the algorithm's unique month-shifting logic (Jan/Feb treated as month 13/14 of prior year) to act correctly. Checks Julian vs. Gregorian centennial drift.
   - *Why it matters:* Chronological edge cases are the number one cause of temporal bugs (e.g., Y2K, leap-year crashes). These tests ensure temporal safety.

## Usage

### Compilation
The project utilizes the Ada `gnatmake` build system wrapped inside a conventional POSIX Makefile.

To compile all files into the `./bin/` directory:
```bash
make
