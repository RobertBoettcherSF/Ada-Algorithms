--  Restoring division — Ada 2023 educational package.
--  Fixed-width signed integer / classical slow-division teaching sketch.
--  Classic restoring (radix-2) with quotient digits in {0,1}: for each bit,
--  shift the partial remainder, trial-subtract the divisor, and restore if
--  the trial went negative (quotient bit 0); otherwise keep the difference
--  (quotient bit 1).
--  Primary sources:
--  https://en.wikipedia.org/wiki/Restoring_division
--  https://en.wikipedia.org/wiki/Division_algorithm
--  Siblings (README): Ada-SRT-Division; upcoming Non-restoring,
--  Newton–Raphson division, Long division, Goldschmidt,
--  Division algorithms survey.

pragma Ada_2022;

package Restoring_Division
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Fixed educational word size
   ------------------------------------------------------------------

   --  N-bit signed operands (two's complement). Quotient and remainder
   --  use the same educational width as the dividend and divisor.
   Operand_Bits : constant := 8;

   Operand_Min : constant := -(2 ** (Operand_Bits - 1));
   Operand_Max : constant :=  (2 ** (Operand_Bits - 1)) - 1;

   --  Distinct integer type (not a subtype of Standard.Integer) so the
   --  Integer convenience overload is unambiguous.
   type Restoring_Operand is range Operand_Min .. Operand_Max;

   subtype Bit is Natural range 0 .. 1;

   --  Quotient bit string for the restoring digit trace (MSB first).
   type Quotient_Bit_Array is array (Natural range <>) of Bit;

   --  Result of one division: N = Q * D + R with Ada truncating semantics
   --  (Q toward zero; R = N rem D, same sign as N when R /= 0).
   type Division_Result is record
      Quotient  : Restoring_Operand;
      Remainder : Restoring_Operand;
   end record;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Bit / two's-complement helpers
   ------------------------------------------------------------------

   function As_Unsigned
     (Value : Integer;
      Width : Positive) return Natural
     with Pre => Width <= 31
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   function Extract_Bit
     (Value : Integer;
      Index : Natural;
      Width : Positive) return Bit
     with Pre => Width <= 31
                 and then Index < Width
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   function To_Twos_Complement_String
     (Value : Integer;
      Width : Positive) return String
     with Pre => Width <= 31
                 and then Width >= 1
                 and then Value >= -(2 ** (Width - 1))
                 and then Value <=  (2 ** (Width - 1)) - 1,
          Global => null;

   ------------------------------------------------------------------
   --  Quotient bit string → integer
   ------------------------------------------------------------------

   --  Convert a radix-2 restoring quotient bit string (MSB first) to a
   --  non-negative integer: Q = Σ q_i · 2^{n-1-i} with q_i ∈ {0,1}.
   function Convert_Quotient_Bits
     (Bit_String : Quotient_Bit_Array) return Natural
     with Global => null;

   ------------------------------------------------------------------
   --  Division
   ------------------------------------------------------------------

   --  Built-in truncating division oracle (Ada `/` and `rem`).
   function Divide_Oracle
     (N, D : Restoring_Operand) return Division_Result
     with Pre => D /= 0,
          Global => null;

   --  Classic restoring division (magnitudes + Ada truncating signs).
   --  Raises Invalid_Argument when D = 0.
   --  Post: N = Q·D + R and R = N rem D (Ada), |R| < |D| or R = 0.
   function Divide_Restoring
     (N, D : Restoring_Operand) return Division_Result
     with Global => null;

   --  Convenience: Standard.Integer operands in Operand_Min .. Operand_Max;
   --  raises Invalid_Argument if out of range or D = 0.
   function Divide_Restoring
     (N, D : Integer) return Division_Result
     with Global => null;

   --  Unsigned-magnitude restoring core used by Divide_Restoring.
   --  Requires 0 ≤ N < 2^Width, D > 0, D < 2^Width; returns Q, R with
   --  N = Q·D + R and 0 ≤ R < D. Bits_Out receives the quotient bit
   --  string MSB-first (Bits_Out'Length = Width, Bits_Out'First = 0).
   procedure Divide_Restoring_Unsigned
     (N, D      : Natural;
      Width     : Positive;
      Quotient  : out Natural;
      Remainder : out Natural;
      Bits_Out  : out Quotient_Bit_Array)
     with Pre => Width <= 16
                 and then Width >= 1
                 and then D > 0
                 and then N < 2 ** Width
                 and then D < 2 ** Width
                 and then Bits_Out'Length = Width
                 and then Bits_Out'First = 0,
          Global => null;

end Restoring_Division;
