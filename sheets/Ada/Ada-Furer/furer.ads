--  Fürer's algorithm educational sketch — Ada 2023.
--  Non-negative integers as base-B digit vectors; schoolbook oracle +
--  exact modular NTT multiplication (cyclic convolution teaching stand-in
--  for Fürer's FFT-based integer multiply).

pragma Ada_2022;

package Furer is

   ------------------------------------------------------------------
   --  Representation
   ------------------------------------------------------------------

   --  Limb radix: each digit is four decimal digits (0 .. 9999).
   Base : constant := 10_000;

   --  Operands up to Max_Operand_Limbs; products fit in Max_Limbs.
   Max_Operand_Limbs : constant := 32;
   Max_Limbs         : constant := 64;

   --  Longer operand limb count at or below this uses schoolbook inside
   --  Multiply_Furer (NTT base case).
   Default_Furer_Threshold : constant Positive := 8;

   --  NTT length is a power of two; product needs N >= Length(A)+Length(B).
   Max_NTT_Length : constant := 64;

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

   function Multiply_NTT (A, B : Digit_Vector) return Digit_Vector;
   --  Exact integer product via number-theoretic transform (NTT) over two
   --  NTT-friendly primes with CRT. Fixed power-of-two length <= Max_NTT_Length.
   --  Always uses NTT (no schoolbook fallback). Raises Invalid_Argument if
   --  the required transform length exceeds Max_NTT_Length.

   function Multiply_Furer
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Furer_Threshold) return Digit_Vector;
   --  Educational Fürer-style multiply: schoolbook when
   --  max(Length(A), Length(B)) <= Threshold, else Multiply_NTT.
   --  Teaching sketch of the convolution / DFT family that underlies Fürer's
   --  2007 improvement over Schönhage–Strassen; not a full multi-dimensional
   --  FFT over intricate rings, and not Harvey–van der Hoeven O(n log n).

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

end Furer;
