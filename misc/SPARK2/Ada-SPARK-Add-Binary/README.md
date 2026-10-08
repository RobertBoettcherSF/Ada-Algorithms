# Ada-SPARK-Add-Binary

Bounded SPARK binary addition on eight-bit buffers; overflow is discarded.

Buffers hold the characters `'0'` and `'1'` only (subtype `Bit`), most
significant bit first; `Add` returns the sum modulo 2**8.
