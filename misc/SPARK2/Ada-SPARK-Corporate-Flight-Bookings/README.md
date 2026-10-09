# Ada-SPARK-Corporate-Flight-Bookings

PLACEHOLDER: only sums all booked seats; no per-flight totals (no range-update / prefix-sum answer); see H120

A small bounded corporate-flight-bookings seat-count kernel.

## Verify

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
