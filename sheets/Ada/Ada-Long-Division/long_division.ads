--  Long_Division — Ada 2023 educational package for Wikipedia "Long division":
--  pencil-and-paper division of non-negative multi-digit integers represented
--  as decimal digit arrays (base 10). Each step forms a partial dividend,
--  finds the largest quotient digit 0..9, subtracts the multiple, and brings
--  down the next digit. Short division covers single-digit divisors.
--  Primary source: https://en.wikipedia.org/wiki/Long_division
--  Siblings (README): Ada-Newton-Raphson-Division, Ada-Non-Restoring-Division,
--  Ada-Restoring-Division, Ada-SRT-Division; upcoming Goldschmidt, Division
--  algorithms survey.

pragma Ada_2022;

package Long_Division
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Representation (decimal digit arrays — hand long division)
   ------------------------------------------------------------------

   --  Limb radix: one decimal digit per limb (0 .. 9), matching the
   --  classroom tableau where each quotient digit is chosen from 0..9.
   Base : constant := 10;

   --  Educational cap: enough for classic examples and Long_Integer
   --  oracles on typical platforms, plus a little room for digit-vector
   --  remainder checks via schoolbook multiply.
   Max_Limbs : constant := 36;

   subtype Digit is Natural range 0 .. Base - 1;
   subtype Digit_Count is Natural range 0 .. Max_Limbs;

   type Digit_Vector is private;

   type Division_Result is record
      Quotient  : Digit_Vector;
      Remainder : Digit_Vector;
   end record;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Construction / conversion
   ------------------------------------------------------------------

   function Zero return Digit_Vector;
   function One  return Digit_Vector;

   function From_Natural (N : Natural) return Digit_Vector;
   function From_Long_Integer (N : Long_Integer) return Digit_Vector;
   --  Non-negative only; N < 0 => Invalid_Argument.

   function From_String (S : String) return Digit_Vector;
   --  Decimal digits only; empty / non-digit / too large => Invalid_Argument.

   function To_String (V : Digit_Vector) return String;

   function To_Natural (V : Digit_Vector) return Natural;
   --  Raises Invalid_Argument if V does not fit in Natural.

   function To_Long_Integer (V : Digit_Vector) return Long_Integer;
   --  Raises Invalid_Argument if V does not fit in Long_Integer.

   ------------------------------------------------------------------
   --  Queries
   ------------------------------------------------------------------

   function Length  (V : Digit_Vector) return Digit_Count;
   function Is_Zero (V : Digit_Vector) return Boolean;
   function Compare (A, B : Digit_Vector) return Integer;
   --  -1 if A < B, 0 if equal, +1 if A > B (non-negative magnitudes).

   function Equal (A, B : Digit_Vector) return Boolean;

   function Get_Digit
     (V : Digit_Vector; Index : Positive) return Digit;
   --  Little-endian: Index 1 = least significant digit. Out of range => 0.

   ------------------------------------------------------------------
   --  Arithmetic helpers (educational building blocks)
   ------------------------------------------------------------------

   function Add (A, B : Digit_Vector) return Digit_Vector;
   function Sub (A, B : Digit_Vector) return Digit_Vector;
   --  Non-negative A >= B; else Invalid_Argument.

   function Multiply_By_Digit
     (A : Digit_Vector; D : Digit) return Digit_Vector;
   --  A * D for D in 0 .. 9 (used when forming q_digit * divisor).

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector;
   --  O(n^2) digit products; oracle helper for remainder identity.

   function Shift_Limbs
     (V : Digit_Vector; K : Natural) return Digit_Vector;
   --  Multiply by 10^K (append K zero low digits).

   ------------------------------------------------------------------
   --  Long / short division
   ------------------------------------------------------------------

   --  Pencil-and-paper long division: for each next dividend digit, form
   --  the partial remainder, choose largest q in 0..9 with
   --  q * Divisor <= Partial, subtract, bring down. Raises
   --  Invalid_Argument if Divisor is zero.
   function Divide_Long
     (Dividend, Divisor : Digit_Vector) return Division_Result;

   --  Short division for a single decimal digit divisor 1 .. 9.
   --  Raises Invalid_Argument if Divisor_Digit = 0.
   function Divide_Short
     (Dividend      : Digit_Vector;
      Divisor_Digit : Digit) return Division_Result;

   --  Convenience: signed integers via magnitudes + Ada truncating signs
   --  (toward zero). Raises Invalid_Argument if Divisor = 0.
   function Divide_Signed
     (Dividend, Divisor : Long_Integer) return Division_Result;
   --  Quotient / Remainder Digit_Vectors hold non-negative magnitudes;
   --  use Divide_Signed_Values for signed Long_Integer pair.

   type Signed_Division_Result is record
      Quotient  : Long_Integer := 0;
      Remainder : Long_Integer := 0;
   end record;

   function Divide_Signed_Values
     (Dividend, Divisor : Long_Integer) return Signed_Division_Result;
   --  Toward-zero Q,R with Dividend = Q*Divisor + Remainder (Ada rem).

   ------------------------------------------------------------------
   --  Oracles (comparison only)
   ------------------------------------------------------------------

   --  Ada Long_Integer truncating division within safe range.
   --  Raises Invalid_Argument if Divisor = 0.
   function Exact_Divide
     (Dividend, Divisor : Long_Integer) return Signed_Division_Result;

private

   type Digit_Array is array (1 .. Max_Limbs) of Digit;

   type Digit_Vector is record
      Len    : Digit_Count := 1;
      Limbs : Digit_Array := [others => 0];
   end record;
   --  Little-endian: Limbs (1) is least significant. Zero is Len = 1,
   --  Limbs (1) = 0. No leading-zero digits when Len > 1.

end Long_Division;
