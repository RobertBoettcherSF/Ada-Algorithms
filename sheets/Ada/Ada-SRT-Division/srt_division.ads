--  SRT division (Sweeney–Robertson–Tocher) — Ada 2023 educational package.
--  Fixed-width signed integer / digit-recurrence teaching sketch (like Booth).
--  Radix-2 SRT with redundant quotient digits in {-1,0,1}, P-D style selection
--  on the shifted partial remainder, then conversion to conventional binary.
--  Primary sources:
--  https://en.wikipedia.org/wiki/SRT_division
--  https://en.wikipedia.org/wiki/Division_algorithm
--  Siblings (README): Ada-Addition-Chain-Exponentiation; upcoming Restoring,
--  Non-restoring, Newton–Raphson division, Long division, Goldschmidt,
--  Division algorithms survey.

pragma Ada_2022;

package SRT_Division
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
   type SRT_Operand is range Operand_Min .. Operand_Max;

   --  Radix-2 redundant quotient digit set.
   type Quotient_Digit is range -1 .. 1;

   type Quotient_Digit_Array is
     array (Natural range <>) of Quotient_Digit;

   subtype Bit is Natural range 0 .. 1;

   --  Result of one division: N = Q * D + R with Ada truncating semantics
   --  (Q toward zero; R = N rem D, same sign as N when R /= 0).
   type Division_Result is record
      Quotient  : SRT_Operand;
      Remainder : SRT_Operand;
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
   --  Digit selection (P-D / threshold form of the SRT lookup)
   ------------------------------------------------------------------

   --  Radix-2 SRT selection on the *shifted* partial remainder P and
   --  positive divisor D: thresholds at ±⌈D/2⌉ so that after
   --  P ← P − q·D the residual stays in the legal redundant range.
   --  Educational full-precision compare (a LUT would use truncated P, D).
   function Select_Quotient_Digit
     (P : Long_Integer;
      D : Long_Integer) return Quotient_Digit
     with Pre => D > 0,
          Global => null;

   --  Convert a radix-2 redundant digit string (MSB first) to a signed
   --  integer: Q = Σ q_i · 2^{n-1-i}.
   function Convert_Redundant_Quotient
     (Digit_String : Quotient_Digit_Array) return Long_Integer
     with Global => null;

   ------------------------------------------------------------------
   --  Division
   ------------------------------------------------------------------

   --  Built-in truncating division oracle (Ada `/` and `rem`).
   function Divide_Oracle
     (N, D : SRT_Operand) return Division_Result
     with Pre => D /= 0,
          Global => null;

   --  Radix-2 SRT: redundant digits {-1,0,1}, then conventional binary.
   --  Raises Invalid_Argument when D = 0.
   --  Post: N = Q·D + R and R = N rem D (Ada), |R| < |D| or R = 0.
   function Divide_SRT
     (N, D : SRT_Operand) return Division_Result
     with Global => null;

   --  Convenience: Standard.Integer operands in Operand_Min .. Operand_Max;
   --  raises Invalid_Argument if out of range or D = 0.
   function Divide_SRT
     (N, D : Integer) return Division_Result
     with Global => null;

   --  Unsigned-magnitude radix-2 SRT core used by Divide_SRT.
   --  Requires 0 ≤ N < 2^Width, D > 0, D < 2^Width; returns Q, R with
   --  N = Q·D + R and 0 ≤ R < D. Digits_Out receives the redundant digit
   --  string MSB-first (Digits_Out'Length = Width, Digits_Out'First = 0).
   procedure Divide_SRT_Unsigned
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

end SRT_Division;
