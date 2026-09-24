--  Long_Division body: decimal digit-vector long / short division.

pragma Ada_2022;

package body Long_Division is

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
      I : Digit_Count := 0;
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

   function From_Long_Integer (N : Long_Integer) return Digit_Vector is
      R : Digit_Vector;
      X : Long_Integer := N;
      I : Digit_Count := 0;
   begin
      if N < 0 then
         raise Invalid_Argument with "From_Long_Integer: negative";
      end if;
      if N = 0 then
         return Zero;
      end if;
      while X > 0 loop
         I := I + 1;
         Ensure_Fits (I);
         R.Limbs (I) := Digit (X mod Long_Integer (Base));
         X := X / Long_Integer (Base);
      end loop;
      R.Len := I;
      return R;
   end From_Long_Integer;

   function From_String (S : String) return Digit_Vector is
      First : Natural := S'First;
      Last  : constant Natural := S'Last;
      Len   : Natural;
      R     : Digit_Vector;
   begin
      if S'Length = 0 then
         raise Invalid_Argument with "empty string";
      end if;

      while First <= Last and then S (First) = '0' loop
         First := First + 1;
      end loop;
      if First > Last then
         return Zero;
      end if;

      for I in First .. Last loop
         if S (I) not in '0' .. '9' then
            raise Invalid_Argument with "non-digit in From_String";
         end if;
      end loop;

      Len := Last - First + 1;
      Ensure_Fits (Len);
      R.Len := Digit_Count (Len);
      --  Most-significant decimal char -> highest index (little-endian).
      for I in 1 .. Len loop
         R.Limbs (I) :=
           Digit (Character'Pos (S (Last - I + 1)) - Character'Pos ('0'));
      end loop;
      return Trim (R);
   end From_String;

   function To_String (V : Digit_Vector) return String is
      T : constant Digit_Vector := Trim (V);
   begin
      if Is_Zero (T) then
         return "0";
      end if;
      declare
         Buf : String (1 .. T.Len);
      begin
         for I in 1 .. T.Len loop
            Buf (T.Len - I + 1) :=
              Character'Val (Character'Pos ('0') + Natural (T.Limbs (I)));
         end loop;
         return Buf;
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

   function To_Long_Integer (V : Digit_Vector) return Long_Integer is
      T   : constant Digit_Vector := Trim (V);
      Acc : Long_Integer := 0;
   begin
      for I in reverse 1 .. T.Len loop
         if Acc > (Long_Integer'Last - Long_Integer (T.Limbs (I)))
           / Long_Integer (Base)
         then
            raise Invalid_Argument with "To_Long_Integer overflow";
         end if;
         Acc := Acc * Long_Integer (Base) + Long_Integer (T.Limbs (I));
      end loop;
      return Acc;
   end To_Long_Integer;

   ------------------------------------------------------------------
   --  Queries
   ------------------------------------------------------------------

   function Length (V : Digit_Vector) return Digit_Count is
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
      if Index > Natural (T.Len) then
         return 0;
      end if;
      return T.Limbs (Index);
   end Get_Digit;

   ------------------------------------------------------------------
   --  Arithmetic helpers
   ------------------------------------------------------------------

   function Add (A, B : Digit_Vector) return Digit_Vector is
      TA    : constant Digit_Vector := Trim (A);
      TB    : constant Digit_Vector := Trim (B);
      R     : Digit_Vector;
      Carry : Natural := 0;
      Max_L : constant Natural :=
        Natural'Max (Natural (TA.Len), Natural (TB.Len));
      Acc   : Natural;
      Da, Db : Natural;
   begin
      for I in 1 .. Max_L loop
         Da := 0;
         Db := 0;
         if I <= Natural (TA.Len) then
            Da := Natural (TA.Limbs (I));
         end if;
         if I <= Natural (TB.Len) then
            Db := Natural (TB.Limbs (I));
         end if;
         Acc := Da + Db + Carry;
         Ensure_Fits (I);
         R.Limbs (I) := Acc mod Base;
         Carry := Acc / Base;
      end loop;
      if Carry /= 0 then
         Ensure_Fits (Max_L + 1);
         R.Limbs (Max_L + 1) := Digit (Carry);
         R.Len := Digit_Count (Max_L + 1);
      else
         R.Len := Digit_Count (Max_L);
         if R.Len = 0 then
            return Zero;
         end if;
      end if;
      return Trim (R);
   end Add;

   function Sub (A, B : Digit_Vector) return Digit_Vector is
      TA     : constant Digit_Vector := Trim (A);
      TB     : constant Digit_Vector := Trim (B);
      R      : Digit_Vector;
      Borrow : Integer := 0;
      Acc    : Integer;
      Da, Db : Integer;
   begin
      if Compare (TA, TB) < 0 then
         raise Invalid_Argument with "Sub underflow";
      end if;
      for I in 1 .. TA.Len loop
         Da := Integer (TA.Limbs (I));
         Db := 0;
         if I <= TB.Len then
            Db := Integer (TB.Limbs (I));
         end if;
         Acc := Da - Db - Borrow;
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

   function Multiply_By_Digit
     (A : Digit_Vector; D : Digit) return Digit_Vector
   is
      TA    : constant Digit_Vector := Trim (A);
      R     : Digit_Vector;
      Carry : Natural := 0;
      Acc   : Natural;
   begin
      if D = 0 or else Is_Zero (TA) then
         return Zero;
      end if;
      for I in 1 .. TA.Len loop
         Acc := Natural (TA.Limbs (I)) * Natural (D) + Carry;
         Ensure_Fits (I);
         R.Limbs (I) := Acc mod Base;
         Carry := Acc / Base;
      end loop;
      R.Len := TA.Len;
      if Carry /= 0 then
         Ensure_Fits (Natural (TA.Len) + 1);
         R.Len := TA.Len + 1;
         R.Limbs (R.Len) := Digit (Carry);
      end if;
      return Trim (R);
   end Multiply_By_Digit;

   function Multiply_Schoolbook (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      R  : Digit_Vector := Zero;
   begin
      if Is_Zero (TA) or else Is_Zero (TB) then
         return Zero;
      end if;
      Ensure_Fits (Natural (TA.Len) + Natural (TB.Len));
      for I in 1 .. TA.Len loop
         declare
            Carry : Natural := 0;
            Acc   : Natural;
            Pos   : Natural;
         begin
            for J in 1 .. TB.Len loop
               Pos := Natural (I) + Natural (J) - 1;
               Acc := Natural (R.Limbs (Pos))
                 + Natural (TA.Limbs (I)) * Natural (TB.Limbs (J))
                 + Carry;
               R.Limbs (Pos) := Acc mod Base;
               Carry := Acc / Base;
            end loop;
            if Carry /= 0 then
               Pos := Natural (I) + Natural (TB.Len);
               Acc := Natural (R.Limbs (Pos)) + Carry;
               R.Limbs (Pos) := Acc mod Base;
               Carry := Acc / Base;
               if Carry /= 0 then
                  Pos := Pos + 1;
                  Ensure_Fits (Pos);
                  R.Limbs (Pos) := Digit (Carry);
               end if;
            end if;
         end;
      end loop;
      R.Len := Digit_Count'Min
        (Max_Limbs, Digit_Count (Natural (TA.Len) + Natural (TB.Len)));
      --  Ensure Len covers highest written digit.
      while R.Len < Max_Limbs
        and then R.Limbs (R.Len + 1) /= 0
      loop
         R.Len := R.Len + 1;
      end loop;
      if R.Limbs (R.Len) = 0 and then R.Len > 1 then
         null;
      end if;
      return Trim (R);
   end Multiply_Schoolbook;

   function Shift_Limbs
     (V : Digit_Vector; K : Natural) return Digit_Vector
   is
      T : constant Digit_Vector := Trim (V);
      R : Digit_Vector;
   begin
      if K = 0 then
         return T;
      end if;
      if Is_Zero (T) then
         return Zero;
      end if;
      Ensure_Fits (Natural (T.Len) + K);
      for I in 1 .. K loop
         R.Limbs (I) := 0;
      end loop;
      for I in 1 .. T.Len loop
         R.Limbs (K + I) := T.Limbs (I);
      end loop;
      R.Len := Digit_Count (Natural (T.Len) + K);
      return R;
   end Shift_Limbs;

   ------------------------------------------------------------------
   --  Quotient-digit search: largest q in 0..9 with q*Divisor <= Partial
   ------------------------------------------------------------------

   function Quotient_Digit
     (Partial : Digit_Vector; Divisor : Digit_Vector) return Digit
   is
      Best : Digit := 0;
      Prod : Digit_Vector;
   begin
      if Is_Zero (Divisor) then
         raise Invalid_Argument with "Quotient_Digit: zero divisor";
      end if;
      if Compare (Partial, Divisor) < 0 then
         return 0;
      end if;
      for Q in reverse Digit range 1 .. 9 loop
         Prod := Multiply_By_Digit (Divisor, Q);
         if Compare (Prod, Partial) <= 0 then
            Best := Q;
            exit;
         end if;
      end loop;
      return Best;
   end Quotient_Digit;

   ------------------------------------------------------------------
   --  Long / short division
   ------------------------------------------------------------------

   function Divide_Long
     (Dividend, Divisor : Digit_Vector) return Division_Result
   is
      A : constant Digit_Vector := Trim (Dividend);
      B : constant Digit_Vector := Trim (Divisor);
      Partial : Digit_Vector := Zero;
      Quot    : Digit_Vector := Zero;
      Rem_V   : Digit_Vector;
      Q_Digit : Digit;
      Started : Boolean := False;
      Q_Len   : Digit_Count := 0;
      --  Collect quotient digits MSD-first then reverse into little-endian.
      Q_Buf   : array (1 .. Max_Limbs) of Digit := [others => 0];
   begin
      if Is_Zero (B) then
         raise Invalid_Argument with "Divide_Long: divisor is zero";
      end if;

      if Compare (A, B) < 0 then
         return (Quotient => Zero, Remainder => A);
      end if;

      --  Process dividend digits from most significant to least.
      for Pos in reverse 1 .. A.Len loop
         --  Bring down: Partial := Partial * 10 + digit
         Partial := Add (Shift_Limbs (Partial, 1),
                         From_Natural (Natural (A.Limbs (Pos))));
         Q_Digit := Quotient_Digit (Partial, B);
         if Q_Digit /= 0 or else Started then
            Started := True;
            Q_Len := Q_Len + 1;
            Ensure_Fits (Natural (Q_Len));
            Q_Buf (Q_Len) := Q_Digit;
         end if;
         if Q_Digit /= 0 then
            Partial := Sub (Partial, Multiply_By_Digit (B, Q_Digit));
         end if;
      end loop;

      if not Started then
         Quot := Zero;
      else
         Quot.Len := Q_Len;
         for I in 1 .. Q_Len loop
            Quot.Limbs (I) := Q_Buf (Q_Len - I + 1);
         end loop;
         Quot := Trim (Quot);
      end if;

      Rem_V := Trim (Partial);
      return (Quotient => Quot, Remainder => Rem_V);
   end Divide_Long;

   function Divide_Short
     (Dividend      : Digit_Vector;
      Divisor_Digit : Digit) return Division_Result
   is
      A       : constant Digit_Vector := Trim (Dividend);
      D       : constant Natural := Natural (Divisor_Digit);
      Rem_Acc : Natural := 0;
      Acc     : Natural;
      Q_Digit : Digit;
      Started : Boolean := False;
      Q_Len   : Digit_Count := 0;
      Q_Buf   : array (1 .. Max_Limbs) of Digit := [others => 0];
      Quot    : Digit_Vector;
   begin
      if Divisor_Digit = 0 then
         raise Invalid_Argument with "Divide_Short: divisor digit is zero";
      end if;

      if Is_Zero (A) then
         return (Quotient => Zero, Remainder => Zero);
      end if;

      for Pos in reverse 1 .. A.Len loop
         Acc := Rem_Acc * Base + Natural (A.Limbs (Pos));
         Q_Digit := Digit (Acc / D);
         Rem_Acc := Acc mod D;
         if Q_Digit /= 0 or else Started then
            Started := True;
            Q_Len := Q_Len + 1;
            Ensure_Fits (Natural (Q_Len));
            Q_Buf (Q_Len) := Q_Digit;
         end if;
      end loop;

      if not Started then
         --  Dividend < divisor (single digit): quotient 0.
         Quot := Zero;
      else
         Quot.Len := Q_Len;
         for I in 1 .. Q_Len loop
            Quot.Limbs (I) := Q_Buf (Q_Len - I + 1);
         end loop;
         Quot := Trim (Quot);
      end if;

      return (Quotient => Quot, Remainder => From_Natural (Rem_Acc));
   end Divide_Short;

   function Divide_Signed
     (Dividend, Divisor : Long_Integer) return Division_Result
   is
      Mag_N : Long_Integer;
      Mag_D : Long_Integer;
      Core  : Division_Result;
   begin
      if Divisor = 0 then
         raise Invalid_Argument with "Divide_Signed: divisor is zero";
      end if;
      if Dividend < 0 then
         Mag_N := -Dividend;
      else
         Mag_N := Dividend;
      end if;
      if Divisor < 0 then
         Mag_D := -Divisor;
      else
         Mag_D := Divisor;
      end if;
      Core := Divide_Long (From_Long_Integer (Mag_N), From_Long_Integer (Mag_D));
      return Core;
   end Divide_Signed;

   function Divide_Signed_Values
     (Dividend, Divisor : Long_Integer) return Signed_Division_Result
   is
      Mag : constant Division_Result := Divide_Signed (Dividend, Divisor);
      Q   : Long_Integer := To_Long_Integer (Mag.Quotient);
      R   : Long_Integer := To_Long_Integer (Mag.Remainder);
   begin
      --  Toward-zero signs (Ada / and rem).
      if (Dividend < 0) xor (Divisor < 0) then
         Q := -Q;
      end if;
      if Dividend < 0 then
         R := -R;
      end if;
      return (Quotient => Q, Remainder => R);
   end Divide_Signed_Values;

   function Exact_Divide
     (Dividend, Divisor : Long_Integer) return Signed_Division_Result
   is
   begin
      if Divisor = 0 then
         raise Invalid_Argument with "Exact_Divide: divisor is zero";
      end if;
      return (Quotient => Dividend / Divisor, Remainder => Dividend rem Divisor);
   end Exact_Divide;

end Long_Division;
