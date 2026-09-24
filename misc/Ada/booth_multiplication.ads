--  Booth's multiplication algorithm — Ada 2023 educational package.
--  Fixed-width signed two's-complement operands (not Digit_Vector big-int).
--  Classic radix-2 Booth scans adjacent multiplier bits (y_i, y_{i-1});
--  optional radix-4 (modified Booth) scans overlapping triples.
--  Primary source:
--  https://en.wikipedia.org/wiki/Booth's_multiplication_algorithm
--  Siblings (README): Ada-Furer, Ada-Karatsuba; upcoming Multiplication
--  algorithms survey, Montgomery reduction.

pragma Ada_2022;

package Booth_Multiplication
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Fixed educational word sizes
   ------------------------------------------------------------------

   --  N-bit signed operands → up to 2N-bit signed product.
   Operand_Bits : constant := 8;
   Product_Bits : constant := 16;  -- 2 * Operand_Bits

   Operand_Min : constant := -(2 ** (Operand_Bits - 1));
   Operand_Max : constant :=  (2 ** (Operand_Bits - 1)) - 1;

   Product_Min : constant := -(2 ** (Product_Bits - 1));
   Product_Max : constant :=  (2 ** (Product_Bits - 1)) - 1;

   --  Distinct integer types (not subtypes of Standard.Integer) so the
   --  Integer→Long_Integer convenience overload is unambiguous.
   type Booth_Operand is range Operand_Min .. Operand_Max;
   type Booth_Product is range Product_Min .. Product_Max;

   subtype Bit is Natural range 0 .. 1;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Bit / two's-complement helpers
   ------------------------------------------------------------------

   --  N-bit two's-complement bit pattern of Value as Natural in 0 .. 2^N-1.
   function As_Unsigned
     (Value : Integer;
      Width : Positive) return Natural
     with Pre => Width <= 31
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   --  Bit Index of the Width-bit two's-complement representation (0 = LSB).
   function Extract_Bit
     (Value : Integer;
      Index : Natural;
      Width : Positive) return Bit
     with Pre => Width <= 31
                 and then Index < Width
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   --  Two's-complement binary string, MSB on the left (e.g. Width=8 → "11111100").
   function To_Twos_Complement_String
     (Value : Integer;
      Width : Positive) return String
     with Pre => Width <= 31
                 and then Width >= 1
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   ------------------------------------------------------------------
   --  Multiplication
   ------------------------------------------------------------------

   --  Built-in multiply oracle (safe for Operand_Bits = 8).
   function Multiply_Oracle
     (X, Y : Booth_Operand) return Booth_Product
     with Global => null;

   --  Classic radix-2 Booth: scan (y_i, y_{i-1}) for i = 0 .. N-1 with y_{-1}=0.
   --    00 / 11 → no op
   --    01      → add  multiplicand * 2^i
   --    10      → sub  multiplicand * 2^i
   --  Explicit Long_Integer accumulator; not a single X*Y.
   function Multiply_Booth
     (X, Y : Booth_Operand) return Booth_Product
     with Global => null;

   --  Convenience: Standard.Integer operands in Operand_Min .. Operand_Max;
   --  raises Invalid_Argument if out of range. Returns Long_Integer product.
   function Multiply_Booth
     (X, Y : Integer) return Long_Integer
     with Global => null;

   --  Radix-4 / modified Booth: overlapping triples (y_{i+1}, y_i, y_{i-1}),
   --  i = 0, 2, ..., N-2. Recodings: 0, +/-1, +/-2 times multiplicand.
   function Multiply_Booth_Radix4
     (X, Y : Booth_Operand) return Booth_Product
     with Global => null;

   --  Wikipedia shift-register formulation (A / S / P of length 2N+1,
   --  with one extra MSB so -2^{N-1} negation does not overflow).
   --  Same results as Multiply_Booth; useful for comparing textbooks.
   function Multiply_Booth_Shift_Register
     (X, Y : Booth_Operand) return Booth_Product
     with Global => null;

end Booth_Multiplication;
