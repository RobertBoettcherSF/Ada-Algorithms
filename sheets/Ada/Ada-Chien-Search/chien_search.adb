--  Chien search — implementation over GF(2^m).

pragma Ada_2022;


package body Chien_Search
  with SPARK_Mode => Off
is

   use type Interfaces.Unsigned_16;

   function SHL
     (Value  : Field_Element;
      Amount : Natural) return Field_Element
   is (Interfaces.Shift_Left (Value, Amount));

   function SHR
     (Value  : Field_Element;
      Amount : Natural) return Field_Element
   is (Interfaces.Shift_Right (Value, Amount));

   ------------------------------------------------------------------
   --  Built-in primitive irreducibles for GF(2^m), m = 2 .. 8.
   --  Each is monic of degree m; the residue of x (value 2) is primitive.
   --  Sources: common coding / AES tables.
   ------------------------------------------------------------------

   --  m=2: x^2+x+1
   --  m=3: x^3+x+1
   --  m=4: x^4+x+1
   --  m=5: x^5+x^2+1
   --  m=6: x^6+x+1
   --  m=7: x^7+x+1
   --  m=8: x^8+x^4+x^3+x^2+1  (AES / Rijndael)
   Irred_Table : constant array (Extension_Degree) of Field_Element :=
     [2 => 2#111#,         -- 7
      3 => 2#1011#,        -- 11
      4 => 2#1_0011#,      -- 19
      5 => 2#100_101#,     -- 37
      6 => 2#100_0011#,    -- 67
      7 => 2#1000_0011#,   -- 131
      8 => 2#1_0001_1101#]; -- 285

   ------------------------------------------------------------------
   --  Validate_Field
   ------------------------------------------------------------------

   procedure Validate_Field (F : Field_Desc) is
      M_Nat : constant Natural := Natural (F.M);
   begin
      --  Extension_Degree already bounds M; still reject inconsistent irr.
      if F.Irreducible = 0 then
         raise Invalid_Argument;
      end if;
      --  Degree of irreducible must be exactly M: bit M set, no higher.
      if (F.Irreducible and SHL (1, M_Nat)) = 0 then
         raise Invalid_Argument;
      end if;
      if SHR (F.Irreducible, M_Nat + 1) /= 0 then
         raise Invalid_Argument;
      end if;
      if F.Primitive = 0 then
         raise Invalid_Argument;
      end if;
   end Validate_Field;

   procedure Validate_Poly (P : Polynomial) is
   begin
      if Is_Zero_Poly (P) then
         raise Invalid_Argument;
      end if;
   end Validate_Poly;

   ------------------------------------------------------------------
   --  Make_GF2 / Field_Order
   ------------------------------------------------------------------

   function Make_GF2 (M : Natural) return Field_Desc is
   begin
      if M < Min_M or else M > Max_M then
         raise Invalid_Argument;
      end if;
      return
        (M           => M,
         Irreducible => Irred_Table (M),
         Primitive   => 2);  -- residue of x
   end Make_GF2;

   function Field_Order (F : Field_Desc) return Natural is
   begin
      return 2 ** Natural (F.M);
   end Field_Order;

   ------------------------------------------------------------------
   --  Add / Mul / Pow / Inv
   ------------------------------------------------------------------

   function Add (A, B : Field_Element) return Field_Element is
   begin
      return A xor B;
   end Add;

   function Mul
     (A, B : Field_Element; F : Field_Desc) return Field_Element
   is
      Result : Field_Element := 0;
      AA     : Field_Element;
      BB     : Field_Element;
      Carry  : Field_Element;
      M_Nat  : constant Natural := Natural (F.M);
      Mask   : constant Field_Element := SHL (1, M_Nat) - 1;
      Irr    : constant Field_Element := F.Irreducible;
   begin
      Validate_Field (F);
      AA := A and Mask;
      BB := B and Mask;
      --  Schoolbook: for each bit of B, conditionally XOR shifted A,
      --  reducing whenever degree m would appear.
      while BB /= 0 loop
         if (BB and 1) /= 0 then
            Result := Result xor AA;
         end if;
         BB := SHR (BB, 1);
         Carry := AA and SHL (1, M_Nat - 1);
         AA := SHL (AA, 1);
         if Carry /= 0 then
            AA := AA xor Irr;
         end if;
         AA := AA and Mask;
      end loop;
      return Result and Mask;
   end Mul;

   function Pow
     (A : Field_Element; Exp : Natural; F : Field_Desc)
      return Field_Element
   is
      Result : Field_Element := 1;
      Base   : Field_Element := A;
      E      : Natural := Exp;
   begin
      if Exp = 0 then
         return 1;
      end if;
      while E > 0 loop
         if (E rem 2) = 1 then
            Result := Mul (Result, Base, F);
         end if;
         Base := Mul (Base, Base, F);
         E := E / 2;
      end loop;
      return Result;
   end Pow;

   function Inv (A : Field_Element; F : Field_Desc) return Field_Element is
      Q : constant Natural := Field_Order (F);
   begin
      if A = 0 then
         raise Invalid_Argument;
      end if;
      --  A^(q-2) = A^{-1} in GF(q)^*.
      return Pow (A, Q - 2, F);
   end Inv;

   ------------------------------------------------------------------
   --  Degree / Is_Zero_Poly / From_Coeffs / Eval
   ------------------------------------------------------------------

   function Degree (P : Polynomial) return Integer is
   begin
      for I in reverse Degree_Index loop
         if P.Coeffs (I) /= 0 then
            return I;
         end if;
      end loop;
      return -1;
   end Degree;

   function Is_Zero_Poly (P : Polynomial) return Boolean is
   begin
      return Degree (P) < 0;
   end Is_Zero_Poly;

   function From_Coeffs
     (C     : Coeff_Array;
      Last  : Degree_Index;
      Field : Field_Desc) return Polynomial
   is
      R     : Polynomial := Zero_Poly;
      M_Nat : constant Natural := Natural (Field.M);
      Mask  : constant Field_Element := SHL (1, M_Nat) - 1;
   begin
      Validate_Field (Field);
      for I in 0 .. Last loop
         if SHR (C (I), M_Nat) /= 0 then
            raise Invalid_Argument;
         end if;
         R.Coeffs (I) := C (I) and Mask;
      end loop;
      return R;
   end From_Coeffs;

   function Eval
     (P : Polynomial; X : Field_Element; F : Field_Desc)
      return Field_Element
   is
      D      : constant Integer := Degree (P);
      Result : Field_Element := 0;
   begin
      if D < 0 then
         return 0;
      end if;
      --  Horner: (((a_n)*x + a_{n-1})*x + ... ) + a_0
      Result := P.Coeffs (Degree_Index (D));
      for I in reverse 0 .. D - 1 loop
         Result := Mul (Result, X, F);
         Result := Add (Result, P.Coeffs (Degree_Index (I)));
      end loop;
      return Result;
   end Eval;

   ------------------------------------------------------------------
   --  Append_Root (internal)
   ------------------------------------------------------------------

   procedure Append_Root
     (Roots : in out Root_Array;
      Count : in out Natural;
      X     :        Field_Element)
   is
   begin
      for I in 1 .. Count loop
         if Roots (I) = X then
            return;
         end if;
      end loop;
      if Count >= Max_Degree then
         return;
      end if;
      Count := Count + 1;
      Roots (Count) := X;
   end Append_Root;

   ------------------------------------------------------------------
   --  Find_Roots (Chien recurrence)
   ------------------------------------------------------------------

   procedure Find_Roots
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
   is
      D     : Integer;
      Q     : Natural;
      Alpha : Field_Element;
      Gamma : array (Degree_Index) of Field_Element := [others => 0];
      Alpha_Pow : array (Degree_Index) of Field_Element := [others => 0];
      Sum   : Field_Element;
      X     : Field_Element;
      T     : Degree_Index;
   begin
      Validate_Field (Field);
      Validate_Poly (Poly);
      Roots := [others => 0];
      Count := 0;

      D := Degree (Poly);
      if D > Integer (Max_Degree) then
         raise Invalid_Argument;
      end if;
      T := Degree_Index (D);
      Q := Field_Order (Field);
      Alpha := Field.Primitive;

      --  Zero root: Λ(0) = λ_0.
      if Poly.Coeffs (0) = 0 then
         Append_Root (Roots, Count, Zero);
      end if;

      --  Initialize γ_j,0 = λ_j and α^j.
      Alpha_Pow (0) := 1;
      Gamma (0) := Poly.Coeffs (0);
      for J in 1 .. T loop
         Alpha_Pow (J) := Mul (Alpha_Pow (J - 1), Alpha, Field);
         Gamma (J) := Poly.Coeffs (J);
      end loop;

      --  Enumerate i = 0 .. q-2 corresponding to α^i.
      X := 1;  -- α^0
      for I in 0 .. Q - 2 loop
         Sum := 0;
         for J in 0 .. T loop
            Sum := Add (Sum, Gamma (J));
         end loop;
         if Sum = 0 then
            Append_Root (Roots, Count, X);
         end if;
         --  γ_{j,i+1} = γ_{j,i} · α^j
         for J in 1 .. T loop
            Gamma (J) := Mul (Gamma (J), Alpha_Pow (J), Field);
         end loop;
         X := Mul (X, Alpha, Field);
      end loop;
   end Find_Roots;

   procedure Chien_Search
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
   is
   begin
      Find_Roots (Field, Poly, Roots, Count);
   end Chien_Search;

   ------------------------------------------------------------------
   --  Find_Roots_Brute
   ------------------------------------------------------------------

   procedure Find_Roots_Brute
     (Field :     Field_Desc;
      Poly  :     Polynomial;
      Roots : out Root_Array;
      Count : out Natural)
   is
      Q     : Natural;
      Alpha : Field_Element;
      X     : Field_Element;
   begin
      Validate_Field (Field);
      Validate_Poly (Poly);
      Roots := [others => 0];
      Count := 0;
      Q := Field_Order (Field);
      Alpha := Field.Primitive;

      if Eval (Poly, Zero, Field) = 0 then
         Append_Root (Roots, Count, Zero);
      end if;

      X := 1;
      for I in 0 .. Q - 2 loop
         if Eval (Poly, X, Field) = 0 then
            Append_Root (Roots, Count, X);
         end if;
         X := Mul (X, Alpha, Field);
      end loop;
   end Find_Roots_Brute;

end Chien_Search;
