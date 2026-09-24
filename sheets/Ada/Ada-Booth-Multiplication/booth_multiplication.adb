--  Booth's multiplication algorithm — Ada 2023 body.
--  Bit-pair / accumulator simulation and wiki shift-register form.

pragma Ada_2022;

package body Booth_Multiplication
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
   --  Oracle
   ------------------------------------------------------------------

   function Multiply_Oracle
     (X, Y : Booth_Operand) return Booth_Product
   is
   begin
      return Booth_Product (Integer (X) * Integer (Y));
   end Multiply_Oracle;

   ------------------------------------------------------------------
   --  Classic radix-2 Booth (bit-pair scan)
   ------------------------------------------------------------------

   function Multiply_Booth
     (X, Y : Booth_Operand) return Booth_Product
   is
      Acc  : Long_Integer := 0;
      Xi   : constant Long_Integer := Long_Integer (X);
      Prev : Bit := 0;  -- y_{-1}
      Curr : Bit;
   begin
      for I in 0 .. Operand_Bits - 1 loop
         Curr := Extract_Bit (Integer (Y), I, Operand_Bits);
         if Curr = 0 and then Prev = 1 then
            --  01: end of a run of 1s → add X * 2^I
            Acc := Acc + Xi * Long_Integer (2 ** I);
         elsif Curr = 1 and then Prev = 0 then
            --  10: start of a run of 1s → subtract X * 2^I
            Acc := Acc - Xi * Long_Integer (2 ** I);
         end if;
         --  00 / 11: no arithmetic
         Prev := Curr;
      end loop;
      return Booth_Product (Acc);
   end Multiply_Booth;

   function Multiply_Booth
     (X, Y : Integer) return Long_Integer
   is
   begin
      if X < Integer (Booth_Operand'First)
        or else X > Integer (Booth_Operand'Last)
        or else Y < Integer (Booth_Operand'First)
        or else Y > Integer (Booth_Operand'Last)
      then
         raise Invalid_Argument;
      end if;
      return Long_Integer
        (Multiply_Booth (Booth_Operand (X), Booth_Operand (Y)));
   end Multiply_Booth;

   ------------------------------------------------------------------
   --  Radix-4 / modified Booth
   ------------------------------------------------------------------

   function Multiply_Booth_Radix4
     (X, Y : Booth_Operand) return Booth_Product
   is
      Acc  : Long_Integer := 0;
      Xi   : constant Long_Integer := Long_Integer (X);
      Prev : Bit := 0;  -- y_{-1}
      Y0   : Bit;
      Y1   : Bit;
      Rec  : Integer;   -- recoded digit in {-2,-1,0,1,2}
   begin
      --  Operand_Bits is even (8); step by 2.
      for I in 0 .. (Operand_Bits / 2) - 1 loop
         Y0 := Extract_Bit (Integer (Y), 2 * I,     Operand_Bits);
         Y1 := Extract_Bit (Integer (Y), 2 * I + 1, Operand_Bits);

         --  Triple (y_{2I+1}, y_{2I}, y_{2I-1}) → recoding table
         case 4 * Integer (Y1) + 2 * Integer (Y0) + Integer (Prev) is
            when 0 | 7 =>
               Rec := 0;           -- 000, 111
            when 1 | 2 =>
               Rec := 1;           -- 001, 010
            when 3 =>
               Rec := 2;           -- 011
            when 4 =>
               Rec := -2;          -- 100
            when 5 | 6 =>
               Rec := -1;          -- 101, 110
            when others =>
               Rec := 0;           -- unreachable for Bit triples
         end case;

         Acc := Acc + Long_Integer (Rec) * Xi
           * Long_Integer (2 ** (2 * I));
         Prev := Y1;  -- becomes y_{(2(I+1))-1} = y_{2I+1}
      end loop;
      return Booth_Product (Acc);
   end Multiply_Booth_Radix4;

   ------------------------------------------------------------------
   --  Wikipedia shift-register formulation (extended for Operand_Min)
   ------------------------------------------------------------------

   function Multiply_Booth_Shift_Register
     (X, Y : Booth_Operand) return Booth_Product
   is
      --  Extended: multiplicand field is Operand_Bits+1 bits so -m for
      --  Operand_Min is representable; total register length =
      --  (Operand_Bits+1) + Operand_Bits + 1 = 2*Operand_Bits+2.
      Ext_X    : constant := Operand_Bits + 1;
      Reg_Bits : constant := Ext_X + Operand_Bits + 1;
      Modulus  : constant Long_Integer := 2 ** Reg_Bits;
      Half     : constant Long_Integer := 2 ** (Reg_Bits - 1);

      function Mask (V : Long_Integer) return Long_Integer is
         R : Long_Integer := V rem Modulus;
      begin
         if R < 0 then
            R := R + Modulus;
         end if;
         return R;
      end Mask;

      function Arith_Shift_Right (V : Long_Integer) return Long_Integer is
         U    : constant Long_Integer := Mask (V);
         Sign : constant Long_Integer := U / Half;  -- 0 or 1
      begin
         return Mask ((U / 2) + Sign * Half);
      end Arith_Shift_Right;

      Xu : constant Natural := As_Unsigned (Integer (X), Operand_Bits);
      Yu : constant Natural := As_Unsigned (Integer (Y), Operand_Bits);

      Xm_Ext : Natural;
      Neg_Xm : Natural;
      A, S, P : Long_Integer;
      Low2    : Natural;
   begin
      --  Sign-extend X to Ext_X bits
      if Extract_Bit (Integer (X), Operand_Bits - 1, Operand_Bits) = 1 then
         Xm_Ext := Xu + (2 ** Operand_Bits);  -- set extra MSB
      else
         Xm_Ext := Xu;
      end if;
      --  -X in Ext_X-bit two's complement
      Neg_Xm := (2 ** Ext_X - Xm_Ext) mod (2 ** Ext_X);

      A := Long_Integer (Xm_Ext) * Long_Integer (2 ** (Operand_Bits + 1));
      S := Long_Integer (Neg_Xm) * Long_Integer (2 ** (Operand_Bits + 1));
      P := Long_Integer (Yu) * 2;  -- r followed by y_{-1}=0; high Ext_X zeros

      A := Mask (A);
      S := Mask (S);
      P := Mask (P);

      for Step in 1 .. Operand_Bits loop
         Low2 := Natural (P rem 4);
         case Low2 is
            when 1 =>      -- 01
               P := Mask (P + A);
            when 2 =>      -- 10
               P := Mask (P + S);
            when others => -- 00, 11
               null;
         end case;
         P := Arith_Shift_Right (P);
      end loop;

      declare
         Raw    : constant Long_Integer := P / 2;
         Prod_U : constant Long_Integer :=
           Raw rem Long_Integer (2 ** Product_Bits);
         Signed : Long_Integer;
      begin
         if Prod_U >= Long_Integer (2 ** (Product_Bits - 1)) then
            Signed := Prod_U - Long_Integer (2 ** Product_Bits);
         else
            Signed := Prod_U;
         end if;
         return Booth_Product (Signed);
      end;
   end Multiply_Booth_Shift_Register;

end Booth_Multiplication;
