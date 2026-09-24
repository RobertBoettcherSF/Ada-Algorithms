--  Multiplication algorithms survey — educational Ada 2023 package.
--  Self-contained sketches: schoolbook, Karatsuba, peasant, lattice,
--  and the three-real-product complex multiply trick.
--  Primary source: https://en.wikipedia.org/wiki/Multiplication_algorithm
--  Do not `with` sibling packages; README links them.

pragma Ada_2022;

package Multiplication_Algorithms is

   ------------------------------------------------------------------
   --  Representation (big-int lite)
   ------------------------------------------------------------------

   --  Limb radix: each digit is four decimal digits (0 .. 9999).
   Base : constant := 10_000;

   --  Operands up to Max_Operand_Limbs limbs; products / Karatsuba temps
   --  fit in Max_Limbs (includes shift room for B^{2m} terms).
   Max_Operand_Limbs : constant := 64;
   Max_Limbs         : constant := 192;

   --  Longer operand limb count at or below this uses schoolbook inside
   --  Multiply_Karatsuba (recursive base case).
   Default_Karatsuba_Threshold : constant Positive := 8;

   subtype Digit is Natural range 0 .. Base - 1;
   subtype Limb_Count is Natural range 0 .. Max_Limbs;

   type Digit_Vector is private;

   --  Educational complex integers for the Karatsuba 3-mul trick.
   type Complex_Int is record
      Re : Long_Integer := 0;
      Im : Long_Integer := 0;
   end record;

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
   --  Digit-vector arithmetic helpers
   ------------------------------------------------------------------

   function Add (A, B : Digit_Vector) return Digit_Vector;
   function Sub
     (A, B : Digit_Vector) return Digit_Vector;
   --  Non-negative A >= B; else Invalid_Argument.

   function Shift_Limbs
     (V : Digit_Vector; K : Natural) return Digit_Vector;
   --  Multiply by Base^K (append K zero low limbs).

   function Double (V : Digit_Vector) return Digit_Vector;
   --  V + V (used by peasant digit sketch).

   function Halve (V : Digit_Vector) return Digit_Vector;
   --  Floor division by 2 (used by peasant digit sketch).

   ------------------------------------------------------------------
   --  Multiplication sketches
   ------------------------------------------------------------------

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector;
   --  Grade-school / long multiplication — O(n^2) limb products; oracle.

   function Multiply_Lattice (A, B : Digit_Vector) return Digit_Vector;
   --  Lattice / grid presentation of schoolbook (same products, diagonal
   --  accumulation). Must agree with Multiply_Schoolbook.

   function Multiply_Karatsuba
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Karatsuba_Threshold) return Digit_Vector;
   --  Classic Karatsuba: three half-size products + shifts.
   --  Recurses; falls back to schoolbook when max(Length(A),Length(B))
   --  <= Threshold.

   function Multiply_Peasant
     (X, Y : Long_Integer) return Long_Integer;
   --  Russian peasant / shift-and-add on non-negative Long_Integer.
   --  Negative operands or overflow => Invalid_Argument.

   function Multiply_Peasant_Digits
     (A, B : Digit_Vector) return Digit_Vector;
   --  Same peasant idea on Digit_Vector (double / halve / add).

   function Multiply_Complex_Naive
     (U, V : Complex_Int) return Complex_Int;
   --  Four real products: (ac-bd) + (ad+bc)i.

   function Multiply_Complex_Karatsuba
     (U, V : Complex_Int) return Complex_Int;
   --  Three real products: p1=ac, p2=bd, p3=(a+b)(c+d);
   --  Re = p1-p2, Im = p3-p1-p2. Overflow => Invalid_Argument.

   ------------------------------------------------------------------
   --  Cross-method compare helpers (tests / demos)
   ------------------------------------------------------------------

   function Products_Agree_Schoolbook_Karatsuba
     (A, B : Digit_Vector) return Boolean;

   function Products_Agree_Schoolbook_Lattice
     (A, B : Digit_Vector) return Boolean;

   function Products_Agree_Schoolbook_Peasant
     (A, B : Digit_Vector) return Boolean;

private

   type Limb_Array is array (1 .. Max_Limbs) of Digit;

   type Digit_Vector is record
      Len   : Limb_Count := 1;
      Limbs : Limb_Array := [others => 0];
   end record;
   --  Little-endian: Limbs (1) is least significant. Zero is Len = 1,
   --  Limbs (1) = 0. No leading-zero limbs when Len > 1.

end Multiplication_Algorithms;
