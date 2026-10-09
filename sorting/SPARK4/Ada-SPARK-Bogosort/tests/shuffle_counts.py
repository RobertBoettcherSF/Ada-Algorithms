#!/usr/bin/env python3
"""Independent model of Bogosort.Sort (bounded random shuffle), written from
the spec comment, not from the Ada body. Prints the expected shuffle count,
outcome, final array and final seed for the fixed-seed cases in tests.adb.

Generator (spec): S := S * 1_664_525 + 1_013_904_223 (mod 2**32), then the
draw is (S / 2**16) mod Bound. Shuffle: Fisher-Yates from the right, for
I = Last downto First + 1 swap A (I) with A (First + Draw (I - First + 1)).
Sort: while A is not sorted and Shuffles < Budget, shuffle once.
"""
def lcg(s):
    return (s * 1664525 + 1013904223) % 2**32

def sort(a, seed, budget):
    a = list(a); n = 0
    srt = lambda x: all(x[i] <= x[i + 1] for i in range(len(x) - 1))
    while not srt(a) and n < budget:
        for i in range(len(a) - 1, 0, -1):
            seed = lcg(seed)
            j = (seed >> 16) % (i + 1)
            a[i], a[j] = a[j], a[i]
        n += 1
    return n, ('Sorted' if srt(a) else 'Gave_Up'), a, seed

MAX = 835_563
CASES = [
    ([3, 1, 2], 1, MAX),
    ([5, 4, 3, 2, 1], 2024, MAX),
    ([2, 1, 2, 1, 2, 1], 7, MAX),
    ([7, 6, 5, 4, 3, 2, 1], 99, MAX),
    ([8, 1, 2, 3, 4, 5, 6, 7], 42, MAX),
    ([2, 1], 5, 0),
    ([7, 6, 5, 4, 3, 2, 1], 99, 10),
    ([4, 3, 2, 1], 3, 2),
]
if __name__ == '__main__':
    for a, s, b in CASES:
        print(a, 'seed', s, 'budget', b, '->', *sort(a, s, b))
