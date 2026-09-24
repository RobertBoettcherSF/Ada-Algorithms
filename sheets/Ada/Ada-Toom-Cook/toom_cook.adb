--  Toom–Cook (Toom-3) body: digit-vector schoolbook + Bodrato Toom-3.

pragma Ada_2022;

package body Toom_Cook is

   ------------------------------------------------------------------
   --  Signed magnitude helpers (evaluation / interpolation)
   ------------------------------------------------------------------

   type Signed_Number is record
      Neg : Boolean := False;
      Mag : Digit_Vector;
   end record;

   function S_Zero return Signed_Number is
     ((Neg => False, Mag => Zero));

   function Make_Signed
     (Neg : Boolean; Mag : Digit_Vector) return Signed_Number
   is
      R : Signed_Number;
   begin
      if Is_Zero (Mag) then
         return S_Zero;
      end if;
      R.Neg := Neg;
      R.Mag := Mag;
      return R;
   end Make_Signed;

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

   function Mul_Small
     (V : Digit_Vector; K : Natural) return Digit_Vector
   is
      T     : constant Digit_Vector := Trim (V);
      R     : Digit_Vector;
      Carry : Natural := 0;
      Acc   : Natural;
   begin
      if K = 0 or else Is_Zero (T) then
         return Zero;
      end if;
      for I in 1 .. T.Len loop
         Acc := Natural (T.Limbs (I)) * K + Carry;
         R.Limbs (I) := Acc mod Base;
         Carry := Acc / Base;
      end loop;
      R.Len := T.Len;
      if Carry /= 0 then
         Ensure_Fits (Natural (T.Len) + 1);
         R.Len := T.Len + 1;
         R.Limbs (R.Len) := Carry;
      end if;
      return Trim (R);
   end Mul_Small;

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
   --  Signed helpers
   ------------------------------------------------------------------

   function S_Add (A, B : Signed_Number) return Signed_Number is
   begin
      if A.Neg = B.Neg then
         return Make_Signed (A.Neg, Add (A.Mag, B.Mag));
      elsif Compare (A.Mag, B.Mag) >= 0 then
         return Make_Signed (A.Neg, Sub (A.Mag, B.Mag));
      else
         return Make_Signed (B.Neg, Sub (B.Mag, A.Mag));
      end if;
   end S_Add;

   function S_Sub (A, B : Signed_Number) return Signed_Number is
      NB : Signed_Number := B;
   begin
      NB.Neg := not B.Neg;
      if Is_Zero (B.Mag) then
         NB.Neg := False;
      end if;
      return S_Add (A, NB);
   end S_Sub;

   function S_Mul_Small
     (A : Signed_Number; K : Integer) return Signed_Number
   is
      Abs_K : Natural;
      Neg   : Boolean;
   begin
      if K = 0 or else Is_Zero (A.Mag) then
         return S_Zero;
      end if;
      if K < 0 then
         Abs_K := Natural (-K);
         Neg := not A.Neg;
      else
         Abs_K := Natural (K);
         Neg := A.Neg;
      end if;
      return Make_Signed (Neg, Mul_Small (A.Mag, Abs_K));
   end S_Mul_Small;

   function Exact_Div_Small
     (A : Signed_Number; K : Positive) return Signed_Number
   is
      --  Exact division of signed magnitude by small positive K (2 or 3).
      T      : constant Digit_Vector := Trim (A.Mag);
      R      : Digit_Vector;
      Rem_V  : Natural := 0;
      Acc    : Natural;
   begin
      if Is_Zero (T) then
         return S_Zero;
      end if;
      for I in reverse 1 .. T.Len loop
         Acc := Rem_V * Base + Natural (T.Limbs (I));
         R.Limbs (I) := Acc / K;
         Rem_V := Acc mod K;
      end loop;
      R.Len := T.Len;
      if Rem_V /= 0 then
         raise Invalid_Argument with "Exact_Div_Small: not divisible";
      end if;
      return Make_Signed (A.Neg, Trim (R));
   end Exact_Div_Small;

   function S_Mul (A, B : Signed_Number; Threshold : Positive)
     return Signed_Number
   is
      Neg : Boolean;
      Mag : Digit_Vector;
   begin
      if Is_Zero (A.Mag) or else Is_Zero (B.Mag) then
         return S_Zero;
      end if;
      Neg := A.Neg xor B.Neg;
      Mag := Multiply_Toom3 (A.Mag, B.Mag, Threshold);
      return Make_Signed (Neg, Mag);
   end S_Mul;

   function Pos (V : Digit_Vector) return Signed_Number is
     (Make_Signed (False, V));

   function Slice
     (V : Digit_Vector; Offset : Natural; Count : Natural)
      return Digit_Vector
   is
      T : constant Digit_Vector := Trim (V);
      R : Digit_Vector;
      N : Limb_Count := 0;
   begin
      if Count = 0 then
         return Zero;
      end if;
      for I in 1 .. Count loop
         declare
            Src : constant Natural := Offset + I;
         begin
            if Src <= Natural (T.Len) then
               N := Limb_Count (I);
               R.Limbs (I) := T.Limbs (Src);
            else
               exit;
            end if;
         end;
      end loop;
      if N = 0 then
         return Zero;
      end if;
      R.Len := N;
      return Trim (R);
   end Slice;

   function S_Shift (A : Signed_Number; K : Natural) return Signed_Number is
   begin
      if Is_Zero (A.Mag) or else K = 0 then
         return A;
      end if;
      return Make_Signed (A.Neg, Shift_Limbs (A.Mag, K));
   end S_Shift;

   function Unsigned_Of (S : Signed_Number) return Digit_Vector is
   begin
      if S.Neg and then not Is_Zero (S.Mag) then
         raise Invalid_Argument with "negative recomposed coefficient";
      end if;
      return S.Mag;
   end Unsigned_Of;

   ------------------------------------------------------------------
   --  Toom-3 (Bodrato points 0, 1, -1, -2, infinity)
   ------------------------------------------------------------------

   function Multiply_Toom3
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Toom3_Threshold) return Digit_Vector
   is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      N  : Limb_Count;
      L  : Natural;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      N := Limb_Count'Max (TA.Len, TB.Len);
      if Natural (N) <= Threshold then
         return Multiply_Schoolbook (TA, TB);
      end if;

      --  Split length so each operand yields three chunks of L limbs.
      L := (Natural (N) + 2) / 3;

      declare
         M0 : constant Digit_Vector := Slice (TA, 0, L);
         M1 : constant Digit_Vector := Slice (TA, L, L);
         M2 : constant Digit_Vector := Slice (TA, 2 * L, L);
         N0 : constant Digit_Vector := Slice (TB, 0, L);
         N1 : constant Digit_Vector := Slice (TB, L, L);
         N2 : constant Digit_Vector := Slice (TB, 2 * L, L);

         type Point_Kind is (P0, P1, Pm1, Pm2, PInf);
         type Point_Array is array (Point_Kind) of Signed_Number;

         function Eval_Points
           (C0, C1, C2 : Digit_Vector) return Point_Array
         is
            S0  : constant Signed_Number := Pos (C0);
            S1  : constant Signed_Number := Pos (C1);
            S2  : constant Signed_Number := Pos (C2);
            Psum : constant Signed_Number := S_Add (S0, S2);  -- m0+m2
            Pts  : Point_Array;
         begin
            Pts (P0)   := S0;
            Pts (PInf) := S2;
            Pts (P1)   := S_Add (Psum, S1);
            Pts (Pm1)  := S_Sub (Psum, S1);
            --  p(-2) = (p(-1) + m2) * 2 - m0
            Pts (Pm2)  := S_Sub
              (S_Mul_Small (S_Add (Pts (Pm1), S2), 2), S0);
            return Pts;
         end Eval_Points;

         PA : constant Point_Array := Eval_Points (M0, M1, M2);
         PB : constant Point_Array := Eval_Points (N0, N1, N2);
         PR : Point_Array;

         R0, R1, R2, R3, R4 : Signed_Number;
         Acc                : Signed_Number;
      begin
         --  Pointwise products (recursive Toom-3 / schoolbook).
         for K in Point_Kind loop
            PR (K) := S_Mul (PA (K), PB (K), Threshold);
         end loop;

         --  Bodrato interpolation.
         R0 := PR (P0);
         R4 := PR (PInf);
         R3 := Exact_Div_Small (S_Sub (PR (Pm2), PR (P1)), 3);
         R1 := Exact_Div_Small (S_Sub (PR (P1), PR (Pm1)), 2);
         R2 := S_Sub (PR (Pm1), PR (P0));
         R3 := S_Add
           (Exact_Div_Small (S_Sub (R2, R3), 2),
            S_Mul_Small (PR (PInf), 2));
         R2 := S_Sub (S_Add (R2, R1), R4);
         R1 := S_Sub (R1, R3);

         --  Recompose: r0 + r1 B^L + r2 B^{2L} + r3 B^{3L} + r4 B^{4L}
         Acc := R0;
         Acc := S_Add (Acc, S_Shift (R1, L));
         Acc := S_Add (Acc, S_Shift (R2, 2 * L));
         Acc := S_Add (Acc, S_Shift (R3, 3 * L));
         Acc := S_Add (Acc, S_Shift (R4, 4 * L));

         return Unsigned_Of (Acc);
      end;
   end Multiply_Toom3;

end Toom_Cook;
