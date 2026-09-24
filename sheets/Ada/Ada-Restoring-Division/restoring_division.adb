--  Restoring division — Ada 2023 body.
--  Classic radix-2 restoring: shift, trial subtract, restore if negative.

pragma Ada_2022;

package body Restoring_Division
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

   ------------------------------------------------------------------
   --  Unsigned restoring core
   ------------------------------------------------------------------

   procedure Divide_Restoring_Unsigned
     (N, D      : Natural;
      Width     : Positive;
      Quotient  : out Natural;
      Remainder : out Natural;
      Bits_Out  : out Quotient_Bit_Array)
   is
      --  Partial remainder; held in Long_Integer so 2R − D stays in range
      --  for Width ≤ 16 (N,D < 2^Width ⇒ R stays < D after restore).
      R     : Long_Integer := 0;
      Dd    : constant Long_Integer := Long_Integer (D);
      Bit_V : Long_Integer;
      Trial : Long_Integer;
   begin
      --  Bring dividend bits MSB-first; each step (Wikipedia restoring):
      --    R ← 2R + n_i;  Trial ← R − D;
      --    if Trial ≥ 0 then q_i := 1; R := Trial
      --                 else q_i := 0; R := R  (restore: add D back)
      for I in 0 .. Width - 1 loop
         Bit_V := Long_Integer ((N / (2 ** (Width - 1 - I))) mod 2);
         R := 2 * R + Bit_V;
         Trial := R - Dd;
         if Trial >= 0 then
            Bits_Out (I) := 1;
            R := Trial;
         else
            Bits_Out (I) := 0;
            --  Restored: R unchanged (equivalent to Trial + D).
         end if;
      end loop;

      Quotient  := Convert_Quotient_Bits (Bits_Out);
      Remainder := Natural (R);
   end Divide_Restoring_Unsigned;

   ------------------------------------------------------------------
   --  Oracle
   ------------------------------------------------------------------

   function Divide_Oracle
     (N, D : Restoring_Operand) return Division_Result
   is
      Ni : constant Integer := Integer (N);
      Di : constant Integer := Integer (D);
   begin
      --  Only overflow of an 8-bit signed quotient: Operand_Min / (-1).
      if N = Restoring_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;
      return (Quotient  => Restoring_Operand (Ni / Di),
              Remainder => Restoring_Operand (Ni rem Di));
   end Divide_Oracle;

   ------------------------------------------------------------------
   --  Signed restoring (magnitudes + Ada truncating signs)
   ------------------------------------------------------------------

   function Divide_Restoring
     (N, D : Restoring_Operand) return Division_Result
   is
      Ni       : constant Integer := Integer (N);
      Di       : constant Integer := Integer (D);
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
         raise Invalid_Argument;
      end if;

      --  Quotient  (-2^{b-1}) / (-1) = 2^{b-1} does not fit in b-bit signed.
      if N = Restoring_Operand'First and then D = -1 then
         raise Invalid_Argument;
      end if;

      Neg_Q := (Ni < 0) /= (Di < 0);
      Abs_N := Natural (abs Long_Integer (Ni));
      Abs_D := Natural (abs Long_Integer (Di));

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

      --  Ada rem: remainder takes the sign of the dividend.
      if Ni < 0 then
         R_Signed := -Integer (R_U);
      else
         R_Signed := Integer (R_U);
      end if;

      return (Quotient  => Restoring_Operand (Q_Signed),
              Remainder => Restoring_Operand (R_Signed));
   end Divide_Restoring;

   function Divide_Restoring
     (N, D : Integer) return Division_Result
   is
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;
      if N < Integer (Restoring_Operand'First)
        or else N > Integer (Restoring_Operand'Last)
        or else D < Integer (Restoring_Operand'First)
        or else D > Integer (Restoring_Operand'Last)
      then
         raise Invalid_Argument;
      end if;
      return Divide_Restoring
        (Restoring_Operand (N), Restoring_Operand (D));
   end Divide_Restoring;

end Restoring_Division;
