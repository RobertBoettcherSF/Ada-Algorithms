--  Toom–Cook multiplication (Toom-3) — educational Ada 2023 package.
--  Non-negative integers as base-B digit vectors; schoolbook oracle + Toom-3.

pragma Ada_2022;

package Toom_Cook is

   ------------------------------------------------------------------
   --  Representation
   ------------------------------------------------------------------

   --  Limb radix: each digit is four decimal digits (0 .. 9999).
   Base : constant := 10_000;

   --  Operands up to Max_Operand_Limbs limbs; products / Toom temps fit
   --  in Max_Limbs (includes shift room for the degree-4 product poly).
   Max_Operand_Limbs : constant := 64;
   Max_Limbs         : constant := 192;

   --  Longer operand limb count at or below this uses schoolbook inside
   --  Multiply_Toom3 (recursive base case).
   Default_Toom3_Threshold : constant Positive := 8;

   subtype Digit is Natural range 0 .. Base - 1;
   subtype Limb_Count is Natural range 0 .. Max_Limbs;

   type Digit_Vector is private;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Construction / conversion
   ------------------------------------------------------------------

   function Zero return Digit_Vector;
   function One  return Digit_Vector;

   function From_Natural (N : Natural) return Digit_Vector;
   function From_String  (S : String)  return Digit_Vector;
   --  Decimal digits only; empty / non-digit / too large => Invalid_Argument.

   function To_String (V : Digit_Vector) return String;
   function To_Natural
     (V : Digit_Vector) return Natural;
   --  Raises Invalid_Argument if V does not fit in Natural.

   ------------------------------------------------------------------
   --  Queries
   ------------------------------------------------------------------

   function Length  (V : Digit_Vector) return Limb_Count;
   function Is_Zero (V : Digit_Vector) return Boolean;
   function Compare (A, B : Digit_Vector) return Integer;
   --  -1 if A < B, 0 if equal, +1 if A > B (non-negative magnitudes).

   function Equal (A, B : Digit_Vector) return Boolean;

   function Get_Digit
     (V : Digit_Vector; Index : Positive) return Digit;
   --  Little-endian: Index 1 = least significant limb. Out of range => 0.

   ------------------------------------------------------------------
   --  Arithmetic
   ------------------------------------------------------------------

   function Add (A, B : Digit_Vector) return Digit_Vector;
   function Sub
     (A, B : Digit_Vector) return Digit_Vector;
   --  Non-negative A >= B; else Invalid_Argument.

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector;

   function Multiply_Toom3
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Toom3_Threshold) return Digit_Vector;
   --  Toom-3 with evaluation points 0, 1, -1, -2, infinity (Bodrato).
   --  Recurses; falls back to schoolbook when max(Length(A),Length(B))
   --  <= Threshold. Point products also use Multiply_Toom3.

   function Shift_Limbs
     (V : Digit_Vector; K : Natural) return Digit_Vector;
   --  Multiply by Base^K (append K zero low limbs).

private

   type Limb_Array is array (1 .. Max_Limbs) of Digit;

   type Digit_Vector is record
      Len   : Limb_Count := 1;
      Limbs : Limb_Array := [others => 0];
   end record;
   --  Little-endian: Limbs (1) is least significant. Zero is Len = 1,
   --  Limbs (1) = 0. No leading-zero limbs when Len > 1.

end Toom_Cook;
