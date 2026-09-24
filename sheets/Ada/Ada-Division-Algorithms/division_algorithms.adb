--  Division_Algorithms body — self-contained educational sketches.

pragma Ada_2022;

package body Division_Algorithms
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Schoolbook     => return "Schoolbook / long division";
         when Restoring      => return "Restoring";
         when Non_Restoring  => return "Non-restoring";
         when SRT_Catalogue  => return "SRT (sibling catalogue)";
         when Newton_Raphson => return "Newton–Raphson";
         when Goldschmidt    => return "Goldschmidt";
         when Oracle         => return "Oracle (Ada / rem)";
      end case;
   end Method_Name;

   function Is_Slow (M : Method_Kind) return Boolean is
   begin
      return M in Schoolbook | Restoring | Non_Restoring | SRT_Catalogue;
   end Is_Slow;

   function Is_Fast (M : Method_Kind) return Boolean is
   begin
      return M in Newton_Raphson | Goldschmidt;
   end Is_Fast;

   function Is_Implemented (M : Method_Kind) return Boolean is
   begin
      return M /= SRT_Catalogue;
   end Is_Implemented;

   ------------------------------------------------------------------
   --  Float helpers
   ------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Rel_Error (Approx, Exact : Long_Float) return Long_Float is
   begin
      if Exact = 0.0 then
         return abs (Approx);
      else
         return abs (Approx - Exact) / abs (Exact);
      end if;
   end Rel_Error;

   ------------------------------------------------------------------
   --  Oracles
   ------------------------------------------------------------------

   function Divide_Oracle (N, D : Integer) return Division_Result is
   begin
      if D = 0 then
         raise Invalid_Argument with "Divide_Oracle: D = 0";
      end if;
      return (Quotient => N / D, Remainder => N rem D);
   end Divide_Oracle;

   function Exact_Quotient (N, D : Long_Float) return Long_Float is
   begin
      if D = 0.0 then
         raise Invalid_Argument with "Exact_Quotient: D = 0";
      end if;
      return N / D;
   end Exact_Quotient;

   ------------------------------------------------------------------
   --  Digit_Vector helpers
   ------------------------------------------------------------------

   function Trim (V : Digit_Vector) return Digit_Vector is
      R : Digit_Vector := V;
   begin
      while R.Len > 1 and then R.Limbs (R.Len) = 0 loop
         R.Len := R.Len - 1;
      end loop;
      return R;
   end Trim;

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
      I : Natural := 0;
   begin
      if N = 0 then
         return Zero;
      end if;
      while X > 0 loop
         I := I + 1;
         if I > Max_Limbs then
            raise Invalid_Argument with "From_Natural: overflow Max_Limbs";
         end if;
         R.Limbs (Digit_Count (I)) := Digit (X rem Base);
         X := X / Base;
      end loop;
      R.Len := Digit_Count (I);
      return R;
   end From_Natural;

   function To_Natural (V : Digit_Vector) return Natural is
      T   : constant Digit_Vector := Trim (V);
      Acc : Natural := 0;
      Pow : Natural := 1;
   begin
      for I in 1 .. T.Len loop
         declare
            Dig : constant Natural := Natural (T.Limbs (I));
         begin
            if Dig > 0 and then Dig > Natural'Last / Pow then
               raise Invalid_Argument with "To_Natural: overflow";
            end if;
            Acc := Acc + Dig * Pow;
            if I < T.Len then
               if Pow > Natural'Last / Base then
                  raise Invalid_Argument with "To_Natural: overflow";
               end if;
               Pow := Pow * Base;
            end if;
         end;
      end loop;
      return Acc;
   end To_Natural;

   function To_String (V : Digit_Vector) return String is
      T : constant Digit_Vector := Trim (V);
   begin
      declare
         Buf : String (1 .. Natural (T.Len));
      begin
         for I in 1 .. T.Len loop
            Buf (Natural (T.Len) - Natural (I) + 1) :=
              Character'Val (Character'Pos ('0') + T.Limbs (I));
         end loop;
         return Buf;
      end;
   end To_String;

   function Is_Zero (V : Digit_Vector) return Boolean is
      T : constant Digit_Vector := Trim (V);
   begin
      return T.Len = 1 and then T.Limbs (1) = 0;
   end Is_Zero;

   function Length (V : Digit_Vector) return Digit_Count is
   begin
      return Trim (V).Len;
   end Length;

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

   function Add (A, B : Digit_Vector) return Digit_Vector is
      TA  : constant Digit_Vector := Trim (A);
      TB  : constant Digit_Vector := Trim (B);
      R   : Digit_Vector;
      Carry : Natural := 0;
      Max_L : constant Digit_Count :=
        Digit_Count'Max (TA.Len, TB.Len);
      Sum : Natural;
   begin
      for I in 1 .. Max_L loop
         Sum := Carry;
         if I <= TA.Len then
            Sum := Sum + Natural (TA.Limbs (I));
         end if;
         if I <= TB.Len then
            Sum := Sum + Natural (TB.Limbs (I));
         end if;
         R.Limbs (I) := Digit (Sum rem Base);
         Carry := Sum / Base;
      end loop;
      if Carry > 0 then
         if Max_L = Max_Limbs then
            raise Invalid_Argument with "Add: overflow";
         end if;
         R.Limbs (Max_L + 1) := Digit (Carry);
         R.Len := Max_L + 1;
      else
         R.Len := Max_L;
      end if;
      return Trim (R);
   end Add;

   function Sub (A, B : Digit_Vector) return Digit_Vector is
      TA : constant Digit_Vector := Trim (A);
      TB : constant Digit_Vector := Trim (B);
      R  : Digit_Vector;
      Borrow : Integer := 0;
      Diff   : Integer;
   begin
      if Compare (TA, TB) < 0 then
         raise Invalid_Argument with "Sub: negative result";
      end if;
      for I in 1 .. TA.Len loop
         Diff := Integer (TA.Limbs (I)) - Borrow;
         if I <= TB.Len then
            Diff := Diff - Integer (TB.Limbs (I));
         end if;
         if Diff < 0 then
            Diff := Diff + Base;
            Borrow := 1;
         else
            Borrow := 0;
         end if;
         R.Limbs (I) := Digit (Diff);
      end loop;
      R.Len := TA.Len;
      return Trim (R);
   end Sub;

   function Multiply_By_Digit
     (A : Digit_Vector; D : Digit) return Digit_Vector
   is
      TA : constant Digit_Vector := Trim (A);
      R  : Digit_Vector;
      Carry : Natural := 0;
      Prod  : Natural;
   begin
      if D = 0 or else Is_Zero (TA) then
         return Zero;
      end if;
      for I in 1 .. TA.Len loop
         Prod := Natural (TA.Limbs (I)) * Natural (D) + Carry;
         R.Limbs (I) := Digit (Prod rem Base);
         Carry := Prod / Base;
      end loop;
      if Carry > 0 then
         if TA.Len = Max_Limbs then
            raise Invalid_Argument with "Multiply_By_Digit: overflow";
         end if;
         R.Limbs (TA.Len + 1) := Digit (Carry);
         R.Len := TA.Len + 1;
      else
         R.Len := TA.Len;
      end if;
      return Trim (R);
   end Multiply_By_Digit;

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
      if Natural (T.Len) + K > Max_Limbs then
         raise Invalid_Argument with "Shift_Limbs: overflow";
      end if;
      for I in 1 .. K loop
         R.Limbs (I) := 0;
      end loop;
      for I in 1 .. T.Len loop
         R.Limbs (K + I) := T.Limbs (I);
      end loop;
      R.Len := Digit_Count (Natural (T.Len) + K);
      return R;
   end Shift_Limbs;

   function Quotient_Digit
     (Partial : Digit_Vector; Divisor : Digit_Vector) return Digit
   is
      Best : Digit := 0;
      Prod : Digit_Vector;
   begin
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
   --  Schoolbook / long division
   ------------------------------------------------------------------

   function Divide_Long
     (Dividend, Divisor : Digit_Vector) return Digit_Division_Result
   is
      A       : constant Digit_Vector := Trim (Dividend);
      B       : constant Digit_Vector := Trim (Divisor);
      Partial : Digit_Vector := Zero;
      Quot    : Digit_Vector := Zero;
      Rem_V   : Digit_Vector;
      Q_Digit : Digit;
      Started : Boolean := False;
      Q_Len   : Digit_Count := 0;
      Q_Buf   : array (1 .. Max_Limbs) of Digit := [others => 0];
   begin
      if Is_Zero (B) then
         raise Invalid_Argument with "Divide_Long: divisor is zero";
      end if;

      if Compare (A, B) < 0 then
         return (Quotient => Zero, Remainder => A);
      end if;

      for Pos in reverse 1 .. A.Len loop
         Partial := Add (Shift_Limbs (Partial, 1),
                         From_Natural (Natural (A.Limbs (Pos))));
         Q_Digit := Quotient_Digit (Partial, B);
         if Q_Digit /= 0 or else Started then
            Started := True;
            Q_Len := Q_Len + 1;
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

   function Divide_Schoolbook (N, D : Natural) return Division_Result is
      Res : Digit_Division_Result;
   begin
      if D = 0 then
         raise Invalid_Argument with "Divide_Schoolbook: D = 0";
      end if;
      Res := Divide_Long (From_Natural (N), From_Natural (D));
      return (Quotient  => Integer (To_Natural (Res.Quotient)),
              Remainder => Integer (To_Natural (Res.Remainder)));
   end Divide_Schoolbook;

   ------------------------------------------------------------------
   --  Restoring
   ------------------------------------------------------------------

   function Convert_Quotient_Bits
     (Bit_String : Quotient_Bit_Array) return Natural
   is
      Acc : Natural := 0;
   begin
      for B of Bit_String loop
         Acc := 2 * Acc + Natural (B);
      end loop;
      return Acc;
   end Convert_Quotient_Bits;

   procedure Divide_Restoring_Unsigned
     (N, D      : Natural;
      Width     : Positive;
      Quotient  : out Natural;
      Remainder : out Natural;
      Bits_Out  : out Quotient_Bit_Array)
   is
      R     : Long_Integer := 0;
      Dd    : constant Long_Integer := Long_Integer (D);
      Bit_V : Long_Integer;
      Trial : Long_Integer;
   begin
      --  R ← 2R + n_i; Trial ← R − D;
      --  if Trial ≥ 0 then q_i := 1; R := Trial else q_i := 0 (restore).
      for I in 0 .. Width - 1 loop
         Bit_V := Long_Integer ((N / (2 ** (Width - 1 - I))) mod 2);
         R := 2 * R + Bit_V;
         Trial := R - Dd;
         if Trial >= 0 then
            Bits_Out (I) := 1;
            R := Trial;
         else
            Bits_Out (I) := 0;
         end if;
      end loop;
      Quotient  := Convert_Quotient_Bits (Bits_Out);
      Remainder := Natural (R);
   end Divide_Restoring_Unsigned;

   function Divide_Restoring (N, D : Integer) return Division_Result is
      Neg_Q    : Boolean;
      Abs_N    : Natural;
      Abs_D    : Natural;
      Q_U      : Natural;
      R_U      : Natural;
      Bit_Buf  : Quotient_Bit_Array (0 .. Operand_Bits - 1);
      Q_Signed : Integer;
      R_Signed : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument with "Divide_Restoring: D = 0";
      end if;
      if N < Operand_Min or else N > Operand_Max
        or else D < Operand_Min or else D > Operand_Max
      then
         raise Invalid_Argument with "Divide_Restoring: out of range";
      end if;
      if N = Operand_Min and then D = -1 then
         raise Invalid_Argument with "Divide_Restoring: overflow Min/-1";
      end if;

      Neg_Q := (N < 0) /= (D < 0);
      Abs_N := Natural (abs Long_Integer (N));
      Abs_D := Natural (abs Long_Integer (D));

      Divide_Restoring_Unsigned
        (N         => Abs_N,
         D         => Abs_D,
         Width     => Operand_Bits,
         Quotient  => Q_U,
         Remainder => R_U,
         Bits_Out  => Bit_Buf);

      if Neg_Q then
         Q_Signed := -Integer (Q_U);
      else
         Q_Signed := Integer (Q_U);
      end if;

      if N < 0 then
         R_Signed := -Integer (R_U);
      else
         R_Signed := Integer (R_U);
      end if;

      return (Quotient => Q_Signed, Remainder => R_Signed);
   end Divide_Restoring;

   ------------------------------------------------------------------
   --  Non-restoring
   ------------------------------------------------------------------

   function Convert_Signed_Digits
     (Digit_String : Signed_Digit_Array) return Long_Integer
   is
      Acc : Long_Integer := 0;
   begin
      for Q of Digit_String loop
         Acc := 2 * Acc + Long_Integer (Q);
      end loop;
      return Acc;
   end Convert_Signed_Digits;

   procedure Divide_Non_Restoring_Unsigned
     (N, D       : Natural;
      Width      : Positive;
      Quotient   : out Natural;
      Remainder  : out Natural;
      Digits_Out : out Signed_Digit_Array)
   is
      R     : Long_Integer := 0;
      Dd    : constant Long_Integer := Long_Integer (D);
      Bit_V : Long_Integer;
      Qacc  : Long_Integer;
   begin
      --  if R ≥ 0 then R ← 2R + n_i − D; q_i := +1
      --            else R ← 2R + n_i + D; q_i := −1
      for I in 0 .. Width - 1 loop
         Bit_V := Long_Integer ((N / (2 ** (Width - 1 - I))) mod 2);
         if R >= 0 then
            R := 2 * R + Bit_V - Dd;
            Digits_Out (I) := 1;
         else
            R := 2 * R + Bit_V + Dd;
            Digits_Out (I) := -1;
         end if;
      end loop;

      Qacc := Convert_Signed_Digits (Digits_Out);

      if R < 0 then
         R := R + Dd;
         Qacc := Qacc - 1;
      end if;

      Quotient  := Natural (Qacc);
      Remainder := Natural (R);
   end Divide_Non_Restoring_Unsigned;

   function Divide_Non_Restoring (N, D : Integer) return Division_Result is
      Neg_Q    : Boolean;
      Abs_N    : Natural;
      Abs_D    : Natural;
      Q_U      : Natural;
      R_U      : Natural;
      Digit_Buf : Signed_Digit_Array (0 .. Operand_Bits - 1);
      Q_Signed : Integer;
      R_Signed : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument with "Divide_Non_Restoring: D = 0";
      end if;
      if N < Operand_Min or else N > Operand_Max
        or else D < Operand_Min or else D > Operand_Max
      then
         raise Invalid_Argument with "Divide_Non_Restoring: out of range";
      end if;
      if N = Operand_Min and then D = -1 then
         raise Invalid_Argument with
           "Divide_Non_Restoring: overflow Min/-1";
      end if;

      Neg_Q := (N < 0) /= (D < 0);
      Abs_N := Natural (abs Long_Integer (N));
      Abs_D := Natural (abs Long_Integer (D));

      Divide_Non_Restoring_Unsigned
        (N          => Abs_N,
         D          => Abs_D,
         Width      => Operand_Bits,
         Quotient   => Q_U,
         Remainder  => R_U,
         Digits_Out => Digit_Buf);

      if Neg_Q then
         Q_Signed := -Integer (Q_U);
      else
         Q_Signed := Integer (Q_U);
      end if;

      if N < 0 then
         R_Signed := -Integer (R_U);
      else
         R_Signed := Integer (R_U);
      end if;

      return (Quotient => Q_Signed, Remainder => R_Signed);
   end Divide_Non_Restoring;

   ------------------------------------------------------------------
   --  Newton–Raphson
   ------------------------------------------------------------------

   function Fail_Float return Float_Division_Result is
   begin
      return
        (Quotient    => 0.0,
         Reciprocal  => 0.0,
         Final_Denom => 0.0,
         Iterations  => 0,
         Status      => Bad_Domain);
   end Fail_Float;

   function Initial_Guess (D : Long_Float) return Long_Float is
      Sign_D    : constant Long_Float :=
        (if D < 0.0 then -1.0 else 1.0);
      M         : Long_Float := abs (D);
      Two_Power : Long_Float := 1.0;
      Inv_M     : Long_Float;
      Guard     : Natural := 0;
   begin
      while M >= 1.0 and then Guard < 2048 loop
         M         := M * 0.5;
         Two_Power := Two_Power * 2.0;
         Guard     := Guard + 1;
      end loop;
      Guard := 0;
      while M < 0.5 and then M > 0.0 and then Guard < 2048 loop
         M         := M * 2.0;
         Two_Power := Two_Power * 0.5;
         Guard     := Guard + 1;
      end loop;

      Inv_M := (48.0 - 32.0 * M) / 17.0;
      if Inv_M <= 0.0 then
         Inv_M := 1.0;
      end if;

      return Sign_D * Inv_M / Two_Power;
   end Initial_Guess;

   function Divide_NR_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Float_Division_Result
   is
      X      : Long_Float;
      X_Next : Long_Float;
      Rel    : Long_Float;
   begin
      if D = 0.0 then
         return Fail_Float;
      end if;

      X := Initial_Guess (D);

      for Iter in 1 .. Max_Iter loop
         X_Next := X * (2.0 - D * X);
         Rel    := abs (X_Next - X);
         X      := X_Next;

         if abs (D * X - 1.0) <= Tol
           or else Rel <= Tol * abs (X)
         then
            return
              (Quotient    => N * X,
               Reciprocal  => X,
               Final_Denom => 0.0,
               Iterations  => Iter,
               Status      => Converged);
         end if;
      end loop;

      return
        (Quotient    => N * X,
         Reciprocal  => X,
         Final_Denom => 0.0,
         Iterations  => Max_Iter,
         Status      => Max_Iterations_Reached);
   end Divide_NR_Detail;

   function Divide_NR (N, D : Long_Float) return Long_Float is
      R : constant Float_Division_Result := Divide_NR_Detail (N, D);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Divide_NR: D = 0 or reciprocal failed to converge";
      end if;
      return R.Quotient;
   end Divide_NR;

   ------------------------------------------------------------------
   --  Goldschmidt
   ------------------------------------------------------------------

   procedure Normalize
     (N_In, D_In : Long_Float;
      N_Out      : out Long_Float;
      D_Out      : out Long_Float;
      Sign_Q     : out Long_Float)
   is
      Abs_N : Long_Float := abs (N_In);
      Abs_D : Long_Float := abs (D_In);
      Guard : Natural := 0;
   begin
      if (N_In < 0.0) xor (D_In < 0.0) then
         Sign_Q := -1.0;
      else
         Sign_Q := 1.0;
      end if;

      while Abs_D > 1.0 and then Guard < 2048 loop
         Abs_D := Abs_D * 0.5;
         Abs_N := Abs_N * 0.5;
         Guard := Guard + 1;
      end loop;
      Guard := 0;
      while Abs_D <= 0.5 and then Abs_D > 0.0 and then Guard < 2048 loop
         Abs_D := Abs_D * 2.0;
         Abs_N := Abs_N * 2.0;
         Guard := Guard + 1;
      end loop;

      N_Out := Abs_N;
      D_Out := Abs_D;
   end Normalize;

   function Divide_Goldschmidt_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Float_Division_Result
   is
      Num    : Long_Float;
      Den    : Long_Float;
      Sign_Q : Long_Float;
      F      : Long_Float;
   begin
      if D = 0.0 then
         return Fail_Float;
      end if;

      Normalize (N, D, Num, Den, Sign_Q);

      if abs (Den - 1.0) <= Tol then
         return
           (Quotient    => Sign_Q * Num,
            Reciprocal  => 0.0,
            Final_Denom => Den,
            Iterations  => 0,
            Status      => Converged);
      end if;

      for Iter in 1 .. Max_Iter loop
         F   := 2.0 - Den;
         Num := Num * F;
         Den := Den * F;

         if abs (Den - 1.0) <= Tol then
            return
              (Quotient    => Sign_Q * Num,
               Reciprocal  => 0.0,
               Final_Denom => Den,
               Iterations  => Iter,
               Status      => Converged);
         end if;
      end loop;

      return
        (Quotient    => Sign_Q * Num,
         Reciprocal  => 0.0,
         Final_Denom => Den,
         Iterations  => Max_Iter,
         Status      => Max_Iterations_Reached);
   end Divide_Goldschmidt_Detail;

   function Divide_Goldschmidt (N, D : Long_Float) return Long_Float is
      R : constant Float_Division_Result :=
        Divide_Goldschmidt_Detail (N, D);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Divide_Goldschmidt: D = 0 or iteration failed to converge";
      end if;
      return R.Quotient;
   end Divide_Goldschmidt;

   ------------------------------------------------------------------
   --  Dispatcher
   ------------------------------------------------------------------

   function Divide
     (N, D   : Integer;
      Method : Method_Kind) return Division_Result
   is
   begin
      case Method is
         when Schoolbook =>
            if N < 0 or else D < 0 then
               raise Invalid_Argument with
                 "Divide(Schoolbook): non-negative only";
            end if;
            return Divide_Schoolbook (Natural (N), Natural (D));
         when Restoring =>
            return Divide_Restoring (N, D);
         when Non_Restoring =>
            return Divide_Non_Restoring (N, D);
         when Oracle =>
            return Divide_Oracle (N, D);
         when SRT_Catalogue =>
            raise Invalid_Argument with
              "Divide: SRT is catalogue-only (see sibling Ada-SRT-Division)";
         when Newton_Raphson | Goldschmidt =>
            raise Invalid_Argument with
              "Divide: use Divide_NR / Divide_Goldschmidt for Float methods";
      end case;
   end Divide;

end Division_Algorithms;
