# Delta encoding

A bounded SPARK teaching component that verifies the endpoint delta of a signed sample stream.

## Index convention

The input array may start at any index (First-relative): the precondition only
bounds its length. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
