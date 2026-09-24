--  Karatsuba body: digit-vector schoolbook + classic three-product Karatsuba.

pragma Ada_2022;

package body Karatsuba is

   function Trim (V : Digit_Vector) return Digit_Vector;

   procedure Ensure_Fits (Len : Natural) is
   begin
      if Len > Max_Limbs then
         raise Invalid_Argument with "result exceeds Max_Limbs";
      end if;
   end Ensure_Fits;

   function Trim (V : Digit_Vector) return Digit_Vector is
      R : Digit_Vector := V;
   begin
      while R.Len > 1 and then R.Limbs (R.Len) = 0 loop
         R.Len := R.Len - 1;
      end loop;
      if R.Len = 0 then
         return Zero;
      end if;
      return R;
   end Trim;

   ------------------------------------------------------------------
   --  Public constructors
   ------------------------------------------------------------------

   function Zero return Digit_Vector is
      Z : Digit_Vector;
   begin
      Z.Len := 1;
      Z.Limbs (1) := 0;
      return Z;
   end Zero;

   function One return Digit_Vector is
      O : Digit_Vector;
   begin
      O.Len := 1;
      O.Limbs (1) := 1;
      return O;
   end One;

   function From_Natural (N : Natural) return Digit_Vector is
      R : Digit_Vector;
      X : Natural := N;
      I : Limb_Count := 0;
   begin
      if N = 0 then
         return Zero;
      end if;
      while X > 0 loop
         I := I + 1;
         Ensure_Fits (I);
         R.Limbs (I) := X mod Base;
         X := X / Base;
      end loop;
      R.Len := I;
      return R;
   end From_Natural;

   function From_String (S : String) return Digit_Vector is
      First : Natural := S'First;
      R     : Digit_Vector := Zero;
   begin
      if S'Length = 0 then
         raise Invalid_Argument with "empty string";
      end if;

      --  Skip leading zeros (but keep a single zero).
      while First <= S'Last and then S (First) = '0' loop
         First := First + 1;
      end loop;
      if First > S'Last then
         return Zero;
      end if;

      for I in First .. S'Last loop
         if S (I) not in '0' .. '9' then
            raise Invalid_Argument with "non-digit in From_String";
         end if;
         --  R := R * 10 + digit
         declare
            Carry : Natural := Character'Pos (S (I)) - Character'Pos ('0');
            J     : Limb_Count := 1;
            Acc   : Natural;
         begin
            while J <= R.Len or else Carry /= 0 loop
               Ensure_Fits (Natural (J));
               Acc := Carry;
               if J <= R.Len then
                  Acc := Acc + Natural (R.Limbs (J)) * 10;
               end if;
               if J > R.Len then
                  R.Len := J;
               end if;
               R.Limbs (J) := Acc mod Base;
               Carry := Acc / Base;
               J := J + 1;
            end loop;
         end;
      end loop;

      if R.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "value exceeds Max_Operand_Limbs";
      end if;
      return Trim (R);
   end From_String;

   function To_String (V : Digit_Vector) return String is
      T : constant Digit_Vector := Trim (V);
   begin
      if Is_Zero (T) then
         return "0";
      end if;

      --  Worst case: Max_Limbs * 4 decimal digits.
      declare
         Buf  : String (1 .. Max_Limbs * 4);
         Last : Natural := Buf'Last;
         X    : Digit_Vector := T;
      begin
         while not Is_Zero (X) loop
            --  Extract one decimal digit: X mod 10, X := X / 10
            declare
               Carry : Natural := 0;
               Acc   : Natural;
            begin
               for I in reverse 1 .. X.Len loop
                  Acc := Carry * Base + Natural (X.Limbs (I));
                  X.Limbs (I) := Acc / 10;
                  Carry := Acc mod 10;
               end loop;
               Buf (Last) := Character'Val (Character'Pos ('0') + Carry);
               Last := Last - 1;
               X := Trim (X);
            end;
         end loop;
         return Buf (Last + 1 .. Buf'Last);
      end;
   end To_String;

   function To_Natural (V : Digit_Vector) return Natural is
      T   : constant Digit_Vector := Trim (V);
      Acc : Natural := 0;
   begin
      for I in reverse 1 .. T.Len loop
         if Acc > (Natural'Last - Natural (T.Limbs (I))) / Base then
            raise Invalid_Argument with "To_Natural overflow";
         end if;
         Acc := Acc * Base + Natural (T.Limbs (I));
      end loop;
      return Acc;
   end To_Natural;

   ------------------------------------------------------------------
   --  Queries
   ------------------------------------------------------------------

   function Length (V : Digit_Vector) return Limb_Count is
   begin
      return Trim (V).Len;
   end Length;

   function Is_Zero (V : Digit_Vector) return Boolean is
      T : constant Digit_Vector := Trim (V);
   begin
      return T.Len = 1 and then T.Limbs (1) = 0;
   end Is_Zero;

   function Compare (A, B : Digit_Vector) return Integer is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
   begin
      if TA.Len < TB.Len then
         return -1;
      elsif TA.Len > TB.Len then
         return 1;
      end if;
      for I in reverse 1 .. TA.Len loop
         if TA.Limbs (I) < TB.Limbs (I) then
            return -1;
         elsif TA.Limbs (I) > TB.Limbs (I) then
            return 1;
         end if;
      end loop;
      return 0;
   end Compare;

   function Equal (A, B : Digit_Vector) return Boolean is
   begin
      return Compare (A, B) = 0;
   end Equal;

   function Get_Digit
     (V : Digit_Vector; Index : Positive) return Digit
   is
      T : constant Digit_Vector := Trim (V);
   begin
      if Index > Positive (T.Len) then
         return 0;
      end if;
      return T.Limbs (Index);
   end Get_Digit;

   ------------------------------------------------------------------
   --  Unsigned add / sub / shift
   ------------------------------------------------------------------

   function Add (A, B : Digit_Vector) return Digit_Vector is
      TA    : constant Digit_Vector := Trim (A);
      TB    : constant Digit_Vector := Trim (B);
      N     : constant Limb_Count :=
        Limb_Count'Max (TA.Len, TB.Len);
      R     : Digit_Vector;
      Carry : Natural := 0;
      Acc   : Natural;
      DA, DB : Natural;
   begin
      for I in 1 .. N loop
         DA := 0;
         DB := 0;
         if I <= TA.Len then
            DA := Natural (TA.Limbs (I));
         end if;
         if I <= TB.Len then
            DB := Natural (TB.Limbs (I));
         end if;
         Acc := DA + DB + Carry;
         Ensure_Fits (Natural (I));
         R.Limbs (I) := Acc mod Base;
         Carry := Acc / Base;
      end loop;
      R.Len := N;
      if Carry /= 0 then
         Ensure_Fits (Natural (N) + 1);
         R.Len := N + 1;
         R.Limbs (R.Len) := Carry;
      end if;
      return Trim (R);
   end Add;

   function Sub (A, B : Digit_Vector) return Digit_Vector is
      TA     : constant Digit_Vector := Trim (A);
      TB     : constant Digit_Vector := Trim (B);
      R      : Digit_Vector;
      Borrow : Integer := 0;
      Acc    : Integer;
      DA, DB : Integer;
   begin
      if Compare (TA, TB) < 0 then
         raise Invalid_Argument with "Sub: negative result";
      end if;
      for I in 1 .. TA.Len loop
         DA := Integer (TA.Limbs (I));
         DB := 0;
         if I <= TB.Len then
            DB := Integer (TB.Limbs (I));
         end if;
         Acc := DA - DB + Borrow;
         if Acc < 0 then
            Acc := Acc + Base;
            Borrow := -1;
         else
            Borrow := 0;
         end if;
         R.Limbs (I) := Digit (Acc);
      end loop;
      R.Len := TA.Len;
      return Trim (R);
   end Sub;

   function Shift_Limbs
     (V : Digit_Vector; K : Natural) return Digit_Vector
   is
      T : constant Digit_Vector := Trim (V);
      R : Digit_Vector;
   begin
      if Is_Zero (T) or else K = 0 then
         return T;
      end if;
      Ensure_Fits (Natural (T.Len) + K);
      for I in 1 .. K loop
         R.Limbs (I) := 0;
      end loop;
      for I in 1 .. T.Len loop
         R.Limbs (I + K) := T.Limbs (I);
      end loop;
      R.Len := T.Len + Limb_Count (K);
      return R;
   end Shift_Limbs;

   ------------------------------------------------------------------
   --  Schoolbook multiply
   ------------------------------------------------------------------

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      R  : Digit_Vector;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      Ensure_Fits (Natural (TA.Len) + Natural (TB.Len));
      R.Len := TA.Len + TB.Len;
      for I in 1 .. R.Len loop
         R.Limbs (I) := 0;
      end loop;

      for I in 1 .. TA.Len loop
         declare
            Carry : Long_Integer := 0;
            Acc   : Long_Integer;
            Pos   : Limb_Count;
         begin
            for J in 1 .. TB.Len loop
               Pos := I + J - 1;
               Acc := Long_Integer (R.Limbs (Pos))
                 + Long_Integer (TA.Limbs (I)) * Long_Integer (TB.Limbs (J))
                 + Carry;
               R.Limbs (Pos) := Digit (Acc mod Long_Integer (Base));
               Carry := Acc / Long_Integer (Base);
            end loop;
            if Carry /= 0 then
               Pos := I + TB.Len;
               Acc := Long_Integer (R.Limbs (Pos)) + Carry;
               R.Limbs (Pos) := Digit (Acc mod Long_Integer (Base));
               Carry := Acc / Long_Integer (Base);
               if Carry /= 0 then
                  Pos := Pos + 1;
                  Ensure_Fits (Natural (Pos));
                  if Pos > R.Len then
                     R.Len := Pos;
                  end if;
                  R.Limbs (Pos) := Digit (Carry);
               end if;
            end if;
         end;
      end loop;
      return Trim (R);
   end Multiply_Schoolbook;

   ------------------------------------------------------------------
   --  Split helpers for Karatsuba
   ------------------------------------------------------------------

   --  Low M limbs of V (or all of V if shorter).
   function Low_Part
     (V : Digit_Vector; M : Positive) return Digit_Vector
   is
      T : constant Digit_Vector := Trim (V);
      R : Digit_Vector;
      N : Limb_Count;
   begin
      if T.Len = 0 or else Is_Zero (T) then
         return Zero;
      end if;
      if Natural (T.Len) <= M then
         return T;
      end if;
      N := Limb_Count (M);
      for I in 1 .. N loop
         R.Limbs (I) := T.Limbs (I);
      end loop;
      R.Len := N;
      return Trim (R);
   end Low_Part;

   --  Limbs starting at index M+1 (V div Base^M).
   function High_Part
     (V : Digit_Vector; M : Positive) return Digit_Vector
   is
      T : constant Digit_Vector := Trim (V);
      R : Digit_Vector;
      N : Limb_Count;
   begin
      if Natural (T.Len) <= M then
         return Zero;
      end if;
      N := T.Len - Limb_Count (M);
      for I in 1 .. N loop
         R.Limbs (I) := T.Limbs (I + M);
      end loop;
      R.Len := N;
      return Trim (R);
   end High_Part;

   ------------------------------------------------------------------
   --  Classic Karatsuba
   ------------------------------------------------------------------
   --
   --  x = x1 * B^m + x0,  y = y1 * B^m + y0
   --  z0 = x0 * y0
   --  z2 = x1 * y1
   --  z1 = (x0 + x1) * (y0 + y1) - z0 - z2
   --  xy = z2 * B^(2m) + z1 * B^m + z0
   --

   function Multiply_Karatsuba
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Karatsuba_Threshold) return Digit_Vector
   is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      N  : Limb_Count;
      M  : Positive;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      N := Limb_Count'Max (TA.Len, TB.Len);
      if N <= Limb_Count (Threshold) then
         return Multiply_Schoolbook (TA, TB);
      end if;

      --  Split near the middle; m >= 1 because N > Threshold >= 1.
      M := Positive (N / 2);

      declare
         X0 : constant Digit_Vector := Low_Part (TA, M);
         X1 : constant Digit_Vector := High_Part (TA, M);
         Y0 : constant Digit_Vector := Low_Part (TB, M);
         Y1 : constant Digit_Vector := High_Part (TB, M);
         Z0 : constant Digit_Vector :=
           Multiply_Karatsuba (X0, Y0, Threshold);
         Z2 : constant Digit_Vector :=
           Multiply_Karatsuba (X1, Y1, Threshold);
         Sx : constant Digit_Vector := Add (X0, X1);
         Sy : constant Digit_Vector := Add (Y0, Y1);
         P  : constant Digit_Vector :=
           Multiply_Karatsuba (Sx, Sy, Threshold);
         Z1 : constant Digit_Vector :=
           Sub (Sub (P, Z0), Z2);
      begin
         --  xy = z2 * B^(2m) + z1 * B^m + z0
         return Add
           (Add (Z0, Shift_Limbs (Z1, M)),
            Shift_Limbs (Z2, 2 * M));
      end;
   end Multiply_Karatsuba;

end Karatsuba;
