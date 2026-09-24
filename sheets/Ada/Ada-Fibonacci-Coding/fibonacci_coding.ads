package Fibonacci_Coding is

   -- Strong typing for algorithm-specific data
   subtype Positive_Integer is Positive;
   
   -- Exception raised for invalid formatting or failed decoding
   Invalid_Code : exception;

   ------------------------------------------------------
   -- Variant 1: Standard Fibonacci Coding (Order 2)   --
   ------------------------------------------------------
   
   -- Encodes a positive integer into a binary string using Zeckendorf's theorem.
   -- Ends with "11" and has no other consecutive 1s.
   function Encode_Fibonacci (N : Positive_Integer) return String;
   
   -- Decodes a standard Fibonacci-encoded binary string back to an integer.
   function Decode_Fibonacci (Code : String) return Positive_Integer;

   ------------------------------------------------------
   -- Variant 2: Generalized Fibonacci Coding (Order N)--
   ------------------------------------------------------
   
   -- Encodes an integer into a binary string that ends with N consecutive 1s
   -- and contains no other instances of N consecutive 1s (e.g., Tribonacci for N=3).
   function Encode_Generalized (N : Positive_Integer; Order : Positive_Integer := 3) return String;
   
   -- Decodes a generalized Fibonacci-encoded binary string back to an integer.
   function Decode_Generalized (Code : String; Order : Positive_Integer := 3) return Positive_Integer;

end Fibonacci_Coding;
