--  Fürer educational body: digit-vector schoolbook + NTT/CRT teaching sketch.

pragma Ada_2022;

package body Furer is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

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
         Ensure_Fits (I);
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
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      R  : Digit_Vector;
      Borrow : Integer := 0;
      Acc    : Integer;
      DA, DB : Integer;
   begin
      if Compare (TA, TB) < 0 then
         raise Invalid_Argument with "Sub underflow";
      end if;
      for I in 1 .. TA.Len loop
         DA := Integer (TA.Limbs (I));
         DB := 0;
         if I <= TB.Len then
            DB := Integer (TB.Limbs (I));
         end if;
         Acc := DA - DB - Borrow;
         if Acc < 0 then
            Acc := Acc + Base;
            Borrow := 1;
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
         R.Limbs (K + I) := T.Limbs (I);
      end loop;
      R.Len := Limb_Count (Natural (T.Len) + K);
      return R;
   end Shift_Limbs;

   ------------------------------------------------------------------
   --  Schoolbook
   ------------------------------------------------------------------

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      R  : Digit_Vector;
      Carry : Natural;
      Acc   : Natural;
      Idx   : Natural;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      R.Len := 1;
      R.Limbs (1) := 0;

      for I in 1 .. TA.Len loop
         Carry := 0;
         for J in 1 .. TB.Len loop
            Idx := Natural (I) + Natural (J) - 1;
            Ensure_Fits (Idx);
            Acc := Natural (R.Limbs (Idx))
              + Natural (TA.Limbs (I)) * Natural (TB.Limbs (J))
              + Carry;
            R.Limbs (Idx) := Acc mod Base;
            Carry := Acc / Base;
            if Idx > Natural (R.Len) then
               R.Len := Limb_Count (Idx);
            end if;
         end loop;
         if Carry /= 0 then
            Idx := Natural (I) + Natural (TB.Len);
            Ensure_Fits (Idx);
            while Idx > Natural (R.Len) loop
               R.Len := R.Len + 1;
               R.Limbs (R.Len) := 0;
            end loop;
            Acc := Natural (R.Limbs (Idx)) + Carry;
            R.Limbs (Idx) := Acc mod Base;
            Carry := Acc / Base;
            if Carry /= 0 then
               Ensure_Fits (Idx + 1);
               if Idx + 1 > Natural (R.Len) then
                  R.Len := Limb_Count (Idx + 1);
                  R.Limbs (R.Len) := 0;
               end if;
               R.Limbs (Idx + 1) :=
                 Digit (Natural (R.Limbs (Idx + 1)) + Carry);
            end if;
         end if;
      end loop;
      return Trim (R);
   end Multiply_Schoolbook;

   ------------------------------------------------------------------
   --  Exact modular NTT (two primes + CRT)
   --
   --  Teaching stand-in for Fürer's FFT-family multiply: integer product via
   --  cyclic convolution computed by DFT over Z/PZ (NTT). Full Fürer uses
   --  multi-dimensional FFTs over intricate rings; Harvey–van der Hoeven
   --  later reached O(n log n). This sketch shares the SS-style NTT core.
   ------------------------------------------------------------------

   --  NTT-friendly primes: P-1 divisible by Max_NTT_Length (= 64).
   Modulus_1 : constant Long_Integer := 998_244_353;   -- 119 * 2^23 + 1
   Modulus_2 : constant Long_Integer := 1_004_535_809; -- 479 * 2^21 + 1
   Root_1    : constant Long_Integer := 3;
   Root_2    : constant Long_Integer := 3;

   --  inv(P1) mod P2 for CRT: P1 * Inv_P1_Mod_P2 ≡ 1 (mod P2)
   Inv_P1_Mod_P2 : constant Long_Integer := 669_690_699;

   subtype NTT_Index is Positive range 1 .. Max_NTT_Length;
   type NTT_Buffer is array (NTT_Index) of Long_Integer;

   function Mod_Mul
     (A, B, M : Long_Integer) return Long_Integer
   is
      --  A, B in 0 .. M-1; M^2 fits in Long_Integer for both moduli.
   begin
      return (A * B) mod M;
   end Mod_Mul;

   function Mod_Pow
     (Base_V, Exp, M : Long_Integer) return Long_Integer
   is
      Result : Long_Integer := 1;
      B      : Long_Integer := Base_V mod M;
      E      : Long_Integer := Exp;
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            Result := Mod_Mul (Result, B, M);
         end if;
         B := Mod_Mul (B, B, M);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   function Mod_Inv (A, M : Long_Integer) return Long_Integer is
   begin
      return Mod_Pow (A, M - 2, M);
   end Mod_Inv;

   procedure Bit_Reverse_Permute (A : in out NTT_Buffer; N : Positive) is
      J : Natural := 0;
      Bit : Natural;
      Tmp : Long_Integer;
   begin
      for I in 0 .. N - 2 loop
         if I < J then
            Tmp := A (I + 1);
            A (I + 1) := A (J + 1);
            A (J + 1) := Tmp;
         end if;
         Bit := N / 2;
         while J >= Bit loop
            J := J - Bit;
            Bit := Bit / 2;
         end loop;
         J := J + Bit;
      end loop;
   end Bit_Reverse_Permute;

   procedure NTT_Transform
     (A       : in out NTT_Buffer;
      N       : Positive;
      M       : Long_Integer;
      Root    : Long_Integer;
      Inverse : Boolean)
   is
      Len : Positive;
      Wlen, W, U, V : Long_Integer;
      Half : Positive;
      Prim_Root_N : Long_Integer;
   begin
      Bit_Reverse_Permute (A, N);

      --  Primitive N-th root of unity: Root^((M-1)/N) mod M
      Prim_Root_N := Mod_Pow (Root, (M - 1) / Long_Integer (N), M);
      if Inverse then
         Prim_Root_N := Mod_Inv (Prim_Root_N, M);
      end if;

      Len := 2;
      while Len <= N loop
         Wlen := Mod_Pow (Prim_Root_N, Long_Integer (N / Len), M);
         Half := Len / 2;
         declare
            I : Natural := 0;
         begin
            while I < N loop
               W := 1;
               for J in 0 .. Half - 1 loop
                  U := A (I + J + 1);
                  V := Mod_Mul (A (I + J + Half + 1), W, M);
                  A (I + J + 1) := (U + V) mod M;
                  A (I + J + Half + 1) := (U - V + M) mod M;
                  W := Mod_Mul (W, Wlen, M);
               end loop;
               I := I + Len;
            end loop;
         end;
         Len := Len * 2;
      end loop;

      if Inverse then
         declare
            Inv_N : constant Long_Integer :=
              Mod_Inv (Long_Integer (N), M);
         begin
            for I in 1 .. N loop
               A (I) := Mod_Mul (A (I), Inv_N, M);
            end loop;
         end;
      end if;
   end NTT_Transform;

   function Next_Pow2 (X : Natural) return Natural is
      P : Natural := 1;
   begin
      while P < X loop
         P := P * 2;
      end loop;
      return P;
   end Next_Pow2;

   function CRT_Combine
     (A1, A2 : Long_Integer) return Long_Integer
   is
      --  x ≡ A1 (mod P1), x ≡ A2 (mod P2), 0 <= x < P1*P2
      T : Long_Integer;
   begin
      T := (A2 - A1) mod Modulus_2;
      T := Mod_Mul (T, Inv_P1_Mod_P2, Modulus_2);
      return A1 + Modulus_1 * T;
   end CRT_Combine;

   function Multiply_NTT (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      Need : Natural;
      N    : Natural;
      FA1, FB1, FA2, FB2 : NTT_Buffer := [others => 0];
      Coeff : Long_Integer;
      R     : Digit_Vector;
      Carry : Long_Integer := 0;
      Acc   : Long_Integer;
      Out_Len : Natural;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      if TA.Len > Max_Operand_Limbs or else TB.Len > Max_Operand_Limbs then
         raise Invalid_Argument with "operand exceeds Max_Operand_Limbs";
      end if;

      --  Linear convolution length; pad to power of two for cyclic NTT.
      Need := Natural (TA.Len) + Natural (TB.Len);
      N := Next_Pow2 (Need);
      if N > Max_NTT_Length then
         raise Invalid_Argument with "NTT length exceeds Max_NTT_Length";
      end if;

      for I in 1 .. TA.Len loop
         FA1 (I) := Long_Integer (TA.Limbs (I));
         FA2 (I) := Long_Integer (TA.Limbs (I));
      end loop;
      for I in 1 .. TB.Len loop
         FB1 (I) := Long_Integer (TB.Limbs (I));
         FB2 (I) := Long_Integer (TB.Limbs (I));
      end loop;

      NTT_Transform (FA1, N, Modulus_1, Root_1, Inverse => False);
      NTT_Transform (FB1, N, Modulus_1, Root_1, Inverse => False);
      NTT_Transform (FA2, N, Modulus_2, Root_2, Inverse => False);
      NTT_Transform (FB2, N, Modulus_2, Root_2, Inverse => False);

      for I in 1 .. N loop
         FA1 (I) := Mod_Mul (FA1 (I), FB1 (I), Modulus_1);
         FA2 (I) := Mod_Mul (FA2 (I), FB2 (I), Modulus_2);
      end loop;

      NTT_Transform (FA1, N, Modulus_1, Root_1, Inverse => True);
      NTT_Transform (FA2, N, Modulus_2, Root_2, Inverse => True);

      --  Carry-propagate CRT coefficients into base-B limbs.
      Out_Len := Need;
      Ensure_Fits (Out_Len);
      R.Len := 1;
      R.Limbs (1) := 0;
      Carry := 0;
      for I in 1 .. Out_Len loop
         Coeff := CRT_Combine (FA1 (I), FA2 (I));
         Acc := Coeff + Carry;
         Ensure_Fits (I);
         R.Limbs (I) := Digit (Acc mod Long_Integer (Base));
         Carry := Acc / Long_Integer (Base);
         R.Len := Limb_Count (I);
      end loop;
      while Carry /= 0 loop
         Out_Len := Out_Len + 1;
         Ensure_Fits (Out_Len);
         R.Limbs (Out_Len) := Digit (Carry mod Long_Integer (Base));
         Carry := Carry / Long_Integer (Base);
         R.Len := Limb_Count (Out_Len);
      end loop;
      return Trim (R);
   end Multiply_NTT;

   function Multiply_Furer
     (A, B      : Digit_Vector;
      Threshold : Positive := Default_Furer_Threshold) return Digit_Vector
   is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      M  : constant Natural :=
        Natural'Max (Natural (TA.Len), Natural (TB.Len));
   begin
      if M <= Threshold then
         return Multiply_Schoolbook (TA, TB);
      end if;
      return Multiply_NTT (TA, TB);
   end Multiply_Furer;

begin
   --  Sanity: Inv_P1_Mod_P2 * Modulus_1 ≡ 1 (mod Modulus_2)
   if Mod_Mul (Inv_P1_Mod_P2, Modulus_1, Modulus_2) /= 1 then
      raise Program_Error with "Inv_P1_Mod_P2 constant is wrong";
   end if;
end Furer;
