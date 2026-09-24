--  SRT division — Ada 2023 body.
--  Radix-2 digit recurrence with redundant digits {-1,0,1}.

pragma Ada_2022;

package body SRT_Division
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   function As_Unsigned
     (Value : Integer;
      Width : Positive) return Natural
   is
      Modulus : constant Natural := 2 ** Width;
   begin
      if Value >= 0 then
         return Natural (Value);
      else
         return Natural (Modulus + Value);
      end if;
   end As_Unsigned;

   function Extract_Bit
     (Value : Integer;
      Index : Natural;
      Width : Positive) return Bit
   is
      U : constant Natural := As_Unsigned (Value, Width);
   begin
      return Bit ((U / (2 ** Index)) mod 2);
   end Extract_Bit;

   function To_Twos_Complement_String
     (Value : Integer;
      Width : Positive) return String
   is
      U   : Natural := As_Unsigned (Value, Width);
      Buf : String (1 .. Width);
   begin
      for I in reverse 1 .. Width loop
         if U rem 2 = 1 then
            Buf (I) := '1';
         else
            Buf (I) := '0';
         end if;
         U := U / 2;
      end loop;
      return Buf;
   end To_Twos_Complement_String;

   ------------------------------------------------------------------
   --  Digit selection and redundant → binary conversion
   ------------------------------------------------------------------

   function Select_Quotient_Digit
     (P : Long_Integer;
      D : Long_Integer) return Quotient_Digit
   is
      --  Thresholds ±⌈D/2⌉. Equivalent educational P-D plot cut for
      --  radix-2 with digit set {-1,0,1} when D > 0.
      Half : constant Long_Integer := (D + 1) / 2;
   begin
      if P >= Half then
         return 1;
      elsif P <= -Half then
         return -1;
      else
         return 0;
      end if;
   end Select_Quotient_Digit;

   function Convert_Redundant_Quotient
     (Digit_String : Quotient_Digit_Array) return Long_Integer
   is
      Acc : Long_Integer := 0;
   begin
      for Q of Digit_String loop
         Acc := 2 * Acc + Long_Integer (Q);
      end loop;
      return Acc;
   end Convert_Redundant_Quotient;

   ------------------------------------------------------------------
   --  Unsigned SRT core
   ------------------------------------------------------------------

   procedure Divide_SRT_Unsigned
     (N, D       : Natural;
      Width      : Positive;
      Quotient   : out Natural;
      Remainder  : out Natural;
      Digits_Out : out Quotient_Digit_Array)
   is
      P     : Long_Integer := 0;
      Dd    : constant Long_Integer := Long_Integer (D);
      Bit_V : Long_Integer;
      Qdig  : Quotient_Digit;
      Qacc  : Long_Integer;
      Racc  : Long_Integer;
   begin
      --  Bring dividend bits MSB-first; each step:
      --    P ← 2P + n_i;  q ← SEL(P, D);  P ← P − q·D
      for I in 0 .. Width - 1 loop
         Bit_V := Long_Integer ((N / (2 ** (Width - 1 - I))) mod 2);
         P := 2 * P + Bit_V;
         Qdig := Select_Quotient_Digit (P, Dd);
         P := P - Long_Integer (Qdig) * Dd;
         Digits_Out (I) := Qdig;
      end loop;

      Qacc := Convert_Redundant_Quotient (Digits_Out);
      Racc := P;

      --  Final correction so 0 ≤ R < D (redundant digits may leave R < 0
      --  or occasionally R ≥ D at the boundary).
      if Racc < 0 then
         Racc := Racc + Dd;
         Qacc := Qacc - 1;
      end if;
      if Racc >= Dd then
         Racc := Racc - Dd;
         Qacc := Qacc + 1;
      end if;

      Quotient  := Natural (Qacc);
      Remainder := Natural (Racc);
   end Divide_SRT_Unsigned;

   ------------------------------------------------------------------
   --  Oracle
   ------------------------------------------------------------------

   function Divide_Oracle
     (N, D : SRT_Operand) return Division_Result
   is
      Ni : constant Integer := Integer (N);
      Di : constant Integer := Integer (D);
   begin
      --  Only overflow of an 8-bit signed quotient: Operand_Min / (-1).
      if N = SRT_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;
      return (Quotient  => SRT_Operand (Ni / Di),
              Remainder => SRT_Operand (Ni rem Di));
   end Divide_Oracle;

   ------------------------------------------------------------------
   --  Signed SRT (magnitudes + Ada truncating signs)
   ------------------------------------------------------------------

   function Divide_SRT
     (N, D : SRT_Operand) return Division_Result
   is
      Ni      : constant Integer := Integer (N);
      Di      : constant Integer := Integer (D);
      Neg_Q   : Boolean;
      Abs_N   : Natural;
      Abs_D   : Natural;
      Q_U     : Natural;
      R_U     : Natural;
      Digit_Buf : Quotient_Digit_Array (0 .. Operand_Bits - 1);
      Q_Signed : Integer;
      R_Signed : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;

      --  Quotient  (-2^{b-1}) / (-1) = 2^{b-1} does not fit in b-bit signed.
      if N = SRT_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;

      Neg_Q := (Ni < 0) /= (Di < 0);
      Abs_N := Natural (abs Long_Integer (Ni));
      Abs_D := Natural (abs Long_Integer (Di));

      Divide_SRT_Unsigned
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

      --  Ada rem: remainder takes the sign of the dividend.
      if Ni < 0 then
         R_Signed := -Integer (R_U);
      else
         R_Signed := Integer (R_U);
      end if;

      return (Quotient  => SRT_Operand (Q_Signed),
              Remainder => SRT_Operand (R_Signed));
   end Divide_SRT;

   function Divide_SRT
     (N, D : Integer) return Division_Result
   is
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;
      if N < Integer (SRT_Operand'First)
        or else N > Integer (SRT_Operand'Last)
        or else D < Integer (SRT_Operand'First)
        or else D > Integer (SRT_Operand'Last)
      then
         raise Invalid_Argument;
      end if;
      return Divide_SRT (SRT_Operand (N), SRT_Operand (D));
   end Divide_SRT;

end SRT_Division;
