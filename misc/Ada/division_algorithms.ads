--  Division_Algorithms — Ada 2023 educational survey package for
--  Wikipedia "Division algorithm": taxonomy + self-contained sketches of
--  schoolbook / long division, restoring, non-restoring, Newton–Raphson
--  reciprocal divide, and Goldschmidt. Oracle via Ada "/" / "rem" and
--  Long_Float "/". Sibling packages (SRT, full long/NR/Goldschmidt, …)
--  are linked in the README only — this repo does not `with` them.
--  Primary source: https://en.wikipedia.org/wiki/Division_algorithm

pragma Ada_2022;

package Division_Algorithms
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy (slow vs fast)
   ------------------------------------------------------------------

   --  Slow: one quotient digit per step. Fast: multiplicative refinement
   --  (roughly doubles correct digits). Oracle: language operators.
   --  SRT is catalogued for the README sibling only (not implemented here).
   type Method_Kind is
     (Schoolbook,
      Restoring,
      Non_Restoring,
      SRT_Catalogue,
      Newton_Raphson,
      Goldschmidt,
      Oracle);

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Is_Slow (M : Method_Kind) return Boolean
     with Global => null;

   function Is_Fast (M : Method_Kind) return Boolean
     with Global => null;

   function Is_Implemented (M : Method_Kind) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Unified integer result / exceptions
   ------------------------------------------------------------------

   --  N = Quotient * D + Remainder with Ada truncating semantics when
   --  signs are supported (toward-zero Q; Rem same sign as N when Rem /= 0).
   type Division_Result is record
      Quotient  : Integer := 0;
      Remainder : Integer := 0;
   end record;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Fixed educational word size (restoring / non-restoring)
   ------------------------------------------------------------------

   Operand_Bits : constant := 8;
   Operand_Min  : constant := -(2 ** (Operand_Bits - 1));
   Operand_Max  : constant :=  (2 ** (Operand_Bits - 1)) - 1;

   subtype Bit is Natural range 0 .. 1;
   type Quotient_Bit_Array is array (Natural range <>) of Bit;

   --  Non-restoring digit set {-1,+1}.
   type Signed_Digit is range -1 .. 1;
   type Signed_Digit_Array is array (Natural range <>) of Signed_Digit;

   ------------------------------------------------------------------
   --  Decimal Digit_Vector (schoolbook / long division)
   ------------------------------------------------------------------

   Base      : constant := 10;
   Max_Limbs : constant := 18;

   subtype Digit is Natural range 0 .. Base - 1;
   subtype Digit_Count is Natural range 0 .. Max_Limbs;

   type Digit_Vector is private;

   type Digit_Division_Result is record
      Quotient  : Digit_Vector;
      Remainder : Digit_Vector;
   end record;

   function Zero return Digit_Vector
     with Global => null;
   function One return Digit_Vector
     with Global => null;

   function From_Natural (N : Natural) return Digit_Vector
     with Global => null;
   function To_Natural (V : Digit_Vector) return Natural
     with Global => null;
   function To_String (V : Digit_Vector) return String
     with Global => null;

   function Is_Zero (V : Digit_Vector) return Boolean
     with Global => null;
   function Length (V : Digit_Vector) return Digit_Count
     with Global => null;
   function Compare (A, B : Digit_Vector) return Integer
     with Global => null;
   --  -1 if A < B, 0 if equal, +1 if A > B.

   ------------------------------------------------------------------
   --  Float fast-division result
   ------------------------------------------------------------------

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 100;
   Near_Tol         : constant Long_Float := 1.0E-9;

   type Float_Status is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Float_Division_Result is record
      Quotient     : Long_Float   := 0.0;
      Reciprocal   : Long_Float   := 0.0;  --  NR only; else 0
      Final_Denom  : Long_Float   := 0.0;  --  Goldschmidt only; else 0
      Iterations   : Natural      := 0;
      Status       : Float_Status := Bad_Domain;
   end record;

   ------------------------------------------------------------------
   --  Numeric helpers
   ------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Rel_Error (Approx, Exact : Long_Float) return Long_Float
     with Global => null;

   ------------------------------------------------------------------
   --  Oracles
   ------------------------------------------------------------------

   --  Ada Integer truncating division: Q = N / D, R = N rem D.
   --  Raises Invalid_Argument if D = 0.
   function Divide_Oracle (N, D : Integer) return Division_Result
     with Global => null;

   --  Exact Long_Float quotient N / D. Raises Invalid_Argument if D = 0.
   function Exact_Quotient (N, D : Long_Float) return Long_Float
     with Global => null;

   ------------------------------------------------------------------
   --  1. Schoolbook / long division (non-negative Digit_Vector)
   ------------------------------------------------------------------

   --  Pencil-and-paper long division in base 10. Raises Invalid_Argument
   --  if Divisor is zero.
   function Divide_Long
     (Dividend, Divisor : Digit_Vector) return Digit_Division_Result
     with Global => null;

   --  Convenience: Natural operands via Digit_Vector schoolbook.
   --  Raises Invalid_Argument if D = 0.
   function Divide_Schoolbook (N, D : Natural) return Division_Result
     with Global => null;

   ------------------------------------------------------------------
   --  2. Restoring (radix-2, educational 8-bit width)
   ------------------------------------------------------------------

   --  Unsigned core: 0 ≤ N < 2^Width, D > 0, D < 2^Width.
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

   --  Magnitudes + Ada truncating signs. Operands in Operand_Min..Operand_Max.
   --  Raises Invalid_Argument if D = 0 or out of range / overflow (Min/-1).
   function Divide_Restoring (N, D : Integer) return Division_Result
     with Global => null;

   ------------------------------------------------------------------
   --  3. Non-restoring (radix-2, same width)
   ------------------------------------------------------------------

   procedure Divide_Non_Restoring_Unsigned
     (N, D       : Natural;
      Width      : Positive;
      Quotient   : out Natural;
      Remainder  : out Natural;
      Digits_Out : out Signed_Digit_Array)
     with Pre => Width <= 16
                 and then Width >= 1
                 and then D > 0
                 and then N < 2 ** Width
                 and then D < 2 ** Width
                 and then Digits_Out'Length = Width
                 and then Digits_Out'First = 0,
          Global => null;

   function Divide_Non_Restoring (N, D : Integer) return Division_Result
     with Global => null;

   ------------------------------------------------------------------
   --  4. Newton–Raphson Float reciprocal divide
   ------------------------------------------------------------------

   --  X ← X (2 − D X), then Q = N · X. D = 0 → Bad_Domain; never raises.
   function Divide_NR_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Float_Division_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Raises Invalid_Argument if D = 0 or not converged.
   function Divide_NR (N, D : Long_Float) return Long_Float
     with Global => null;

   ------------------------------------------------------------------
   --  5. Goldschmidt Float
   ------------------------------------------------------------------

   --  F_i = 2 − D_i; N ← N F_i; D ← D F_i until D → 1.
   function Divide_Goldschmidt_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Float_Division_Result
     with Pre => Tol >= 0.0, Global => null;

   function Divide_Goldschmidt (N, D : Long_Float) return Long_Float
     with Global => null;

   ------------------------------------------------------------------
   --  Dispatcher (integer methods)
   ------------------------------------------------------------------

   --  Schoolbook accepts non-negative only; Restoring / Non_Restoring /
   --  Oracle accept signed in educational range (Schoolbook / Oracle
   --  Natural and Integer respectively). SRT_Catalogue / float methods
   --  raise Invalid_Argument here — use the Float APIs instead.
   function Divide
     (N, D   : Integer;
      Method : Method_Kind) return Division_Result
     with Global => null;

private

   type Digit_Array is array (1 .. Max_Limbs) of Digit;

   --  Little-endian: Limbs (1) is least significant. Zero is Len = 1,
   --  Limbs (1) = 0. No leading-zero digits when Len > 1.
   type Digit_Vector is record
      Len   : Digit_Count := 1;
      Limbs : Digit_Array := [others => 0];
   end record;

end Division_Algorithms;
