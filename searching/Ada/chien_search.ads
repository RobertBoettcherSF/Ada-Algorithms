--  Chien search — Ada 2023 educational package.
--  Find roots of a univariate polynomial over GF(2^m) via the Chien
--  recurrence (constant multiplications by powers of a primitive element).
--  Primary source: https://en.wikipedia.org/wiki/Chien_search
--  Field elements are bitmasks (bit i = coefficient of x^i); multiplication
--  reduces modulo a fixed irreducible of degree m (m = 2 .. 8).
--  Role: locating roots of error-locator polynomials in BCH / Reed–Solomon
--  decoding. Contrast: naive Horner / brute-force evaluation.

pragma Ada_2022;

with Interfaces;

package Chien_Search
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Bounds and exceptions
   ------------------------------------------------------------------

   --  Soft classroom bound: highest power of x that fits in a Polynomial.
   Max_Degree : constant := 16;

   --  Extension degree of the primary field GF(2^m).
   Min_M : constant := 2;
   Max_M : constant := 8;

   subtype Degree_Index is Natural range 0 .. Max_Degree;
   subtype Extension_Degree is Natural range Min_M .. Max_M;

   --  Bitmask representation of an element of GF(2^m), m ≤ 8.
   --  Bit i holds the coefficient of α^i when the field is F_2[α]/(p(α)).
   subtype Field_Element is Interfaces.Unsigned_16;

   Zero : constant Field_Element := 0;
   One  : constant Field_Element := 1;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Field descriptor (fixed irreducible + primitive element)
   ------------------------------------------------------------------

   --  Irreducible is the bit-mask of a monic irreducible of degree M
   --  (bit M set). Primitive is a generator of the multiplicative group
   --  (standard choice: the residue of x, value 2, for the built-in tables).
   type Field_Desc is record
      M           : Extension_Degree;
      Irreducible : Field_Element;
      Primitive   : Field_Element;
   end record;

   --  Built-in GF(2^m) with a standard primitive irreducible and α = x.
   --  Raises Invalid_Argument if M not in Min_M .. Max_M.
   function Make_GF2 (M : Natural) return Field_Desc
     with Global => null;

   --  Cardinality q = 2^M.
   function Field_Order (F : Field_Desc) return Natural
     with Global => null;

   ------------------------------------------------------------------
   --  Dense univariate polynomials over GF(2^m)
   --  Convention: Coeffs(I) is the coefficient of X^I (constant at 0).
   --  Degree of the zero polynomial is -1.
   ------------------------------------------------------------------

   type Coeff_Array is array (Degree_Index) of Field_Element;

   type Polynomial is record
      Coeffs : Coeff_Array := [others => 0];
   end record;

   Zero_Poly : constant Polynomial := (Coeffs => [others => 0]);

   --  Distinct non-zero field roots (and optionally zero); order is the
   --  Chien enumeration order α^0, α^1, … then zero if present.
   type Root_Array is array (1 .. Max_Degree) of Field_Element;

   ------------------------------------------------------------------
   --  Field arithmetic GF(2^m)
   ------------------------------------------------------------------

   --  Addition = XOR (characteristic 2).
   function Add (A, B : Field_Element) return Field_Element
     with Global => null,
          Inline;

   --  Polynomial multiplication mod Irreducible (schoolbook + reduce).
   --  Raises Invalid_Argument if F.M is inconsistent with Irreducible.
   function Mul
     (A, B : Field_Element; F : Field_Desc) return Field_Element
     with Global => null;

   --  A^Exp in the field (binary exponentiation).
   function Pow
     (A : Field_Element; Exp : Natural; F : Field_Desc)
      return Field_Element
     with Global => null;

   --  Multiplicative inverse via A^(q-2). Raises Invalid_Argument if A = 0.
   function Inv (A : Field_Element; F : Field_Desc) return Field_Element
     with Global => null;

   ------------------------------------------------------------------
   --  Polynomial helpers
   ------------------------------------------------------------------

   function Degree (P : Polynomial) return Integer
     with Global => null,
          Post   => Degree'Result >= -1
            and then Degree'Result <= Integer (Max_Degree);

   function Is_Zero_Poly (P : Polynomial) return Boolean
     with Global => null;

   --  Build from low-degree-first coefficients C(0) .. C(Last).
   --  Raises Invalid_Argument if Last > Max_Degree (impossible by type)
   --  or if any coefficient uses bits above F.M.
   function From_Coeffs
     (C     : Coeff_Array;
      Last  : Degree_Index;
      Field : Field_Desc) return Polynomial
     with Global => null;

   --  Horner evaluation P(X) over the field.
   function Eval
     (P : Polynomial; X : Field_Element; F : Field_Desc)
      return Field_Element
     with Global => null;

   ------------------------------------------------------------------
   --  Root finding
   ------------------------------------------------------------------

   --  Chien search: enumerate non-zero field elements as α^i and update
   --  term registers γ_j ← γ_j · α^j each step (O(t) constant multiplies
   --  per field element). Also reports X = 0 when the constant term is 0.
   --  Writes distinct roots into Roots(1 .. Count). Count ≤ deg(P).
   --  Raises Invalid_Argument if:
   --    Field.M out of range / Irreducible inconsistent,
   --    deg(P) > Max_Degree (soft), or P is the zero polynomial.
   procedure Find_Roots
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
     with Global => null;

   --  Alias of Find_Roots (textbook name).
   procedure Chien_Search
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
     with Global => null;

   --  Brute-force oracle: Horner-evaluate at every field element.
   --  Same Invalid_Argument rules as Find_Roots.
   procedure Find_Roots_Brute
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
     with Global => null;

end Chien_Search;
