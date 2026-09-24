--  Non-restoring division — Ada 2023 educational package.
--  Fixed-width signed integer / classical slow-division teaching sketch.
--  Radix-2 non-restoring with quotient digits in {-1,1} (no 0): for each
--  bit, shift the partial remainder and either subtract or add the divisor
--  according to the sign of R — there is no restore step. Final correction
--  if the remainder is negative; convert {-1,1} digits to binary.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Non-restoring_division
--  https://en.wikipedia.org/wiki/Division_algorithm
--  Siblings (README): Ada-Restoring-Division, Ada-SRT-Division; upcoming
--  Newton–Raphson division, Long division, Goldschmidt,
--  Division algorithms survey.

pragma Ada_2022;

package Non_Restoring_Division
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
   type Non_Restoring_Operand is range Operand_Min .. Operand_Max;

   --  Non-restoring quotient digit set {-1,1} (0 unused; range matches SRT).
   type Quotient_Digit is range -1 .. 1;

   type Quotient_Digit_Array is
     array (Natural range <>) of Quotient_Digit;

   subtype Bit is Natural range 0 .. 1;

   --  Result of one division: N = Q * D + R with Ada truncating semantics
   --  (Q toward zero; R = N rem D, same sign as N when R /= 0).
   type Division_Result is record
      Quotient  : Non_Restoring_Operand;
      Remainder : Non_Restoring_Operand;
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
   --  {-1,1} digit string → integer
   ------------------------------------------------------------------

   --  Convert a radix-2 non-restoring digit string (MSB first) to an
   --  integer: Q = Σ q_i · 2^{n-1-i} with q_i ∈ {-1,1}. Equivalent to
   --  Wikipedia's P − M form (positive vs negative digit masks).
   function Convert_Non_Restoring_Quotient
     (Digit_String : Quotient_Digit_Array) return Long_Integer
     with Global => null;

   ------------------------------------------------------------------
   --  Division
   ------------------------------------------------------------------

   --  Built-in truncating division oracle (Ada `/` and `rem`).
   function Divide_Oracle
     (N, D : Non_Restoring_Operand) return Division_Result
     with Pre => D /= 0,
          Global => null;

   --  Classic non-restoring division (magnitudes + Ada truncating signs).
   --  Raises Invalid_Argument when D = 0.
   --  Post: N = Q·D + R and R = N rem D (Ada), |R| < |D| or R = 0.
   function Divide_Non_Restoring
     (N, D : Non_Restoring_Operand) return Division_Result
     with Global => null;

   --  Convenience: Standard.Integer operands in Operand_Min .. Operand_Max;
   --  raises Invalid_Argument if out of range or D = 0.
   function Divide_Non_Restoring
     (N, D : Integer) return Division_Result
     with Global => null;

   --  Unsigned-magnitude non-restoring core used by Divide_Non_Restoring.
   --  Requires 0 ≤ N < 2^Width, D > 0, D < 2^Width; returns Q, R with
   --  N = Q·D + R and 0 ≤ R < D. Digits_Out receives the {-1,1} digit
   --  string MSB-first (Digits_Out'Length = Width, Digits_Out'First = 0).
   procedure Divide_Non_Restoring_Unsigned
     (N, D       : Natural;
      Width      : Positive;
      Quotient   : out Natural;
      Remainder  : out Natural;
      Digits_Out : out Quotient_Digit_Array)
     with Pre => Width <= 16
                 and then Width >= 1
                 and then D > 0
                 and then N < 2 ** Width
                 and then D < 2 ** Width
                 and then Digits_Out'Length = Width
                 and then Digits_Out'First = 0,
          Global => null;

end Non_Restoring_Division;
