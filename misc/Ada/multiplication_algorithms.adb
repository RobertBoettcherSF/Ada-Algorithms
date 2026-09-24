--  Multiplication algorithms survey body: schoolbook, lattice, Karatsuba,
--  peasant (Long_Integer + Digit_Vector), complex 3-mul trick.

pragma Ada_2022;

package body Multiplication_Algorithms is

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

      declare
         Buf  : String (1 .. Max_Limbs * 4);
         Last : Natural := Buf'Last;
         X    : Digit_Vector := T;
      begin
         while not Is_Zero (X) loop
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
   --  Unsigned add / sub / shift / double / halve
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

   function Double (V : Digit_Vector) return Digit_Vector is
   begin
      return Add (V, V);
   end Double;

   function Halve (V : Digit_Vector) return Digit_Vector is
      T     : constant Digit_Vector := Trim (V);
      R     : Digit_Vector;
      Carry : Natural := 0;
      Acc   : Natural;
   begin
      if Is_Zero (T) then
         return Zero;
      end if;
      for I in reverse 1 .. T.Len loop
         Acc := Carry * Base + Natural (T.Limbs (I));
         R.Limbs (I) := Acc / 2;
         Carry := Acc mod 2;
      end loop;
      R.Len := T.Len;
      return Trim (R);
   end Halve;

   ------------------------------------------------------------------
   --  Schoolbook multiply (oracle)
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
   --  Lattice / grid multiply (same products, diagonal-style accumulate)
   ------------------------------------------------------------------
   --
   --  For each digit pair (A_i, B_j) form the product P = A_i * B_j
   --  (two decimal "cells" in classical lattice; here one limb product).
   --  Write P into positions I+J-1 and I+J (low / high of the limb
   --  product), then normalize carries — algebraically identical to
   --  schoolbook, presented as a lattice grid.
   --

   function Multiply_Lattice (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      --  Acc holds unnormalized column sums (wider than Digit).
      type Wide_Array is array (1 .. Max_Limbs) of Long_Integer;
      Acc_Cols : Wide_Array := [others => 0];
      Max_Pos  : Natural := 0;
      R        : Digit_Vector;
      Carry    : Long_Integer;
      Pos      : Natural;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      for I in 1 .. TA.Len loop
         for J in 1 .. TB.Len loop
            declare
               Prod : constant Long_Integer :=
                 Long_Integer (TA.Limbs (I)) * Long_Integer (TB.Limbs (J));
               Low  : constant Long_Integer := Prod mod Long_Integer (Base);
               High : constant Long_Integer := Prod / Long_Integer (Base);
               P0   : constant Natural := Natural (I) + Natural (J) - 1;
               P1   : constant Natural := P0 + 1;
            begin
               Acc_Cols (P0) := Acc_Cols (P0) + Low;
               Acc_Cols (P1) := Acc_Cols (P1) + High;
               if P1 > Max_Pos then
                  Max_Pos := P1;
               end if;
            end;
         end loop;
      end loop;

      Ensure_Fits (Max_Pos);
      Carry := 0;
      for K in 1 .. Max_Pos loop
         declare
            Tot : constant Long_Integer := Acc_Cols (K) + Carry;
         begin
            R.Limbs (Limb_Count (K)) := Digit (Tot mod Long_Integer (Base));
            Carry := Tot / Long_Integer (Base);
         end;
      end loop;
      Pos := Max_Pos;
      R.Len := Limb_Count (Max_Pos);
      while Carry /= 0 loop
         Pos := Pos + 1;
         Ensure_Fits (Pos);
         R.Limbs (Limb_Count (Pos)) := Digit (Carry mod Long_Integer (Base));
         Carry := Carry / Long_Integer (Base);
         R.Len := Limb_Count (Pos);
      end loop;
      return Trim (R);
   end Multiply_Lattice;

   ------------------------------------------------------------------
   --  Split helpers for Karatsuba
   ------------------------------------------------------------------

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
         return Add
           (Add (Z0, Shift_Limbs (Z1, M)),
            Shift_Limbs (Z2, 2 * M));
      end;
   end Multiply_Karatsuba;

   ------------------------------------------------------------------
   --  Russian peasant / shift-and-add (Long_Integer)
   ------------------------------------------------------------------

   function Safe_Add (P, Q : Long_Integer) return Long_Integer is
   begin
      if Q > 0 and then P > Long_Integer'Last - Q then
         raise Invalid_Argument with "peasant add overflow";
      end if;
      if Q < 0 and then P < Long_Integer'First - Q then
         raise Invalid_Argument with "peasant add overflow";
      end if;
      return P + Q;
   end Safe_Add;

   function Safe_Double (P : Long_Integer) return Long_Integer is
   begin
      if P > Long_Integer'Last / 2 then
         raise Invalid_Argument with "peasant double overflow";
      end if;
      if P < Long_Integer'First / 2 then
         raise Invalid_Argument with "peasant double overflow";
      end if;
      return P * 2;
   end Safe_Double;

   function Multiply_Peasant
     (X, Y : Long_Integer) return Long_Integer
   is
      A : Long_Integer := X;
      B : Long_Integer := Y;
      R : Long_Integer := 0;
   begin
      if X < 0 or else Y < 0 then
         raise Invalid_Argument with "peasant requires non-negative";
      end if;
      if X = 0 or else Y = 0 then
         return 0;
      end if;

      while B > 0 loop
         if B rem 2 = 1 then
            R := Safe_Add (R, A);
         end if;
         B := B / 2;
         if B > 0 then
            A := Safe_Double (A);
         end if;
      end loop;
      return R;
   end Multiply_Peasant;

   ------------------------------------------------------------------
   --  Peasant on Digit_Vector
   ------------------------------------------------------------------

   function Is_Odd (V : Digit_Vector) return Boolean is
      T : constant Digit_Vector := Trim (V);
   begin
      return (Natural (T.Limbs (1)) rem 2) = 1;
   end Is_Odd;

   function Multiply_Peasant_Digits
     (A, B : Digit_Vector) return Digit_Vector
   is
      Mult : Digit_Vector := Trim (A);
      Mulr : Digit_Vector := Trim (B);
      R    : Digit_Vector := Zero;
   begin
      if Is_Zero (Mult) or else Is_Zero (Mulr) then
         return Zero;
      end if;
      if Mult.Len > Max_Operand_Limbs or else Mulr.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      while not Is_Zero (Mulr) loop
         if Is_Odd (Mulr) then
            R := Add (R, Mult);
         end if;
         Mulr := Halve (Mulr);
         if not Is_Zero (Mulr) then
            Mult := Double (Mult);
         end if;
      end loop;
      return R;
   end Multiply_Peasant_Digits;

   ------------------------------------------------------------------
   --  Complex multiply: naive 4-mul vs Karatsuba 3-mul
   ------------------------------------------------------------------

   function Mag (X : Long_Integer) return Long_Integer is
   begin
      if X >= 0 then
         return X;
      elsif X = Long_Integer'First then
         raise Invalid_Argument with "complex mul overflow";
      else
         return -X;
      end if;
   end Mag;

   function Safe_Mul_LI (P, Q : Long_Integer) return Long_Integer is
      --  Pre-check via |P|*|Q| so we never rely on Long_Long_Integer
      --  (may equal Long_Integer on this target).
      Limit : constant Long_Integer := Long_Integer'Last;
      AP    : constant Long_Integer := Mag (P);
      AQ    : constant Long_Integer := Mag (Q);
   begin
      if AP /= 0 and then AQ > Limit / AP then
         raise Invalid_Argument with "complex mul overflow";
      end if;
      return P * Q;
   end Safe_Mul_LI;

   function Safe_Sub_LI (P, Q : Long_Integer) return Long_Integer is
   begin
      if Q > 0 and then P < Long_Integer'First + Q then
         raise Invalid_Argument with "complex sub overflow";
      end if;
      if Q < 0 and then P > Long_Integer'Last + Q then
         raise Invalid_Argument with "complex sub overflow";
      end if;
      return P - Q;
   end Safe_Sub_LI;

   function Multiply_Complex_Naive
     (U, V : Complex_Int) return Complex_Int
   is
      AC : constant Long_Integer := Safe_Mul_LI (U.Re, V.Re);
      BD : constant Long_Integer := Safe_Mul_LI (U.Im, V.Im);
      AD : constant Long_Integer := Safe_Mul_LI (U.Re, V.Im);
      BC : constant Long_Integer := Safe_Mul_LI (U.Im, V.Re);
   begin
      return (Re => Safe_Sub_LI (AC, BD),
              Im => Safe_Add (AD, BC));
   end Multiply_Complex_Naive;

   function Multiply_Complex_Karatsuba
     (U, V : Complex_Int) return Complex_Int
   is
      P1 : constant Long_Integer := Safe_Mul_LI (U.Re, V.Re);
      P2 : constant Long_Integer := Safe_Mul_LI (U.Im, V.Im);
      P3 : constant Long_Integer :=
        Safe_Mul_LI (Safe_Add (U.Re, U.Im), Safe_Add (V.Re, V.Im));
      Re_Part : constant Long_Integer := Safe_Sub_LI (P1, P2);
      Im_Part : constant Long_Integer :=
        Safe_Sub_LI (Safe_Sub_LI (P3, P1), P2);
   begin
      return (Re => Re_Part, Im => Im_Part);
   end Multiply_Complex_Karatsuba;

   ------------------------------------------------------------------
   --  Cross-method agreement helpers
   ------------------------------------------------------------------

   function Products_Agree_Schoolbook_Karatsuba
     (A, B : Digit_Vector) return Boolean
   is
   begin
      return Equal (Multiply_Schoolbook (A, B), Multiply_Karatsuba (A, B));
   end Products_Agree_Schoolbook_Karatsuba;

   function Products_Agree_Schoolbook_Lattice
     (A, B : Digit_Vector) return Boolean
   is
   begin
      return Equal (Multiply_Schoolbook (A, B), Multiply_Lattice (A, B));
   end Products_Agree_Schoolbook_Lattice;

   function Products_Agree_Schoolbook_Peasant
     (A, B : Digit_Vector) return Boolean
   is
   begin
      return Equal
        (Multiply_Schoolbook (A, B), Multiply_Peasant_Digits (A, B));
   end Products_Agree_Schoolbook_Peasant;

end Multiplication_Algorithms;
