--  Non-restoring division — Ada 2023 body.
--  Radix-2 non-restoring: shift, add or subtract by sign of R, no restore.

pragma Ada_2022;

package body Non_Restoring_Division
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

   function Convert_Non_Restoring_Quotient
     (Digit_String : Quotient_Digit_Array) return Long_Integer
   is
      Acc : Long_Integer := 0;
   begin
      for Q of Digit_String loop
         Acc := 2 * Acc + Long_Integer (Q);
      end loop;
      return Acc;
   end Convert_Non_Restoring_Quotient;

   ------------------------------------------------------------------
   --  Unsigned non-restoring core
   ------------------------------------------------------------------

   procedure Divide_Non_Restoring_Unsigned
     (N, D       : Natural;
      Width      : Positive;
      Quotient   : out Natural;
      Remainder  : out Natural;
      Digits_Out : out Quotient_Digit_Array)
   is
      --  Partial remainder; Long_Integer so 2R ± D stays in range for
      --  Width ≤ 16 (after correction, 0 ≤ R < D).
      R     : Long_Integer := 0;
      Dd    : constant Long_Integer := Long_Integer (D);
      Bit_V : Long_Integer;
      Qacc  : Long_Integer;
   begin
      --  Bring dividend bits MSB-first; each step (Wikipedia non-restoring
      --  with bit-serial educational form parallel to restoring sibling):
      --    if R ≥ 0 then R ← 2R + n_i − D;  q_i := +1
      --              else R ← 2R + n_i + D;  q_i := −1
      --  No restore step. Digits are in {-1,+1}.
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

      Qacc := Convert_Non_Restoring_Quotient (Digits_Out);

      --  Final correction: remainder in −D ≤ R < D; make 0 ≤ R < D.
      --  Quotients before correction are always odd (Wikipedia).
      if R < 0 then
         R := R + Dd;
         Qacc := Qacc - 1;
      end if;

      Quotient  := Natural (Qacc);
      Remainder := Natural (R);
   end Divide_Non_Restoring_Unsigned;

   ------------------------------------------------------------------
   --  Oracle
   ------------------------------------------------------------------

   function Divide_Oracle
     (N, D : Non_Restoring_Operand) return Division_Result
   is
      Ni : constant Integer := Integer (N);
      Di : constant Integer := Integer (D);
   begin
      --  Only overflow of an 8-bit signed quotient: Operand_Min / (-1).
      if N = Non_Restoring_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;
      return (Quotient  => Non_Restoring_Operand (Ni / Di),
              Remainder => Non_Restoring_Operand (Ni rem Di));
   end Divide_Oracle;

   ------------------------------------------------------------------
   --  Signed non-restoring (magnitudes + Ada truncating signs)
   ------------------------------------------------------------------

   function Divide_Non_Restoring
     (N, D : Non_Restoring_Operand) return Division_Result
   is
      Ni       : constant Integer := Integer (N);
      Di       : constant Integer := Integer (D);
      Neg_Q    : Boolean;
      Abs_N    : Natural;
      Abs_D    : Natural;
      Q_U      : Natural;
      R_U      : Natural;
      Digit_Buf : Quotient_Digit_Array (0 .. Operand_Bits - 1);
      Q_Signed : Integer;
      R_Signed : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;

      --  Quotient  (-2^{b-1}) / (-1) = 2^{b-1} does not fit in b-bit signed.
      if N = Non_Restoring_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;

      Neg_Q := (Ni < 0) /= (Di < 0);
      Abs_N := Natural (abs Long_Integer (Ni));
      Abs_D := Natural (abs Long_Integer (Di));

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

      --  Ada rem: remainder takes the sign of the dividend.
      if Ni < 0 then
         R_Signed := -Integer (R_U);
      else
         R_Signed := Integer (R_U);
      end if;

      return (Quotient  => Non_Restoring_Operand (Q_Signed),
              Remainder => Non_Restoring_Operand (R_Signed));
   end Divide_Non_Restoring;

   function Divide_Non_Restoring
     (N, D : Integer) return Division_Result
   is
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;
      if N < Integer (Non_Restoring_Operand'First)
        or else N > Integer (Non_Restoring_Operand'Last)
        or else D < Integer (Non_Restoring_Operand'First)
        or else D > Integer (Non_Restoring_Operand'Last)
      then
         raise Invalid_Argument;
      end if;
      return Divide_Non_Restoring
        (Non_Restoring_Operand (N), Non_Restoring_Operand (D));
   end Divide_Non_Restoring;

end Non_Restoring_Division;
