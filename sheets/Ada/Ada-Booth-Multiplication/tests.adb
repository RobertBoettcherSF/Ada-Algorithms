--  Standalone test suite for Booth_Multiplication (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Booth_Multiplication; use Booth_Multiplication;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Agree (X, Y : Booth_Operand) return Boolean is
      O : constant Booth_Product := Multiply_Oracle (X, Y);
      B : constant Booth_Product := Multiply_Booth (X, Y);
      R : constant Booth_Product := Multiply_Booth_Radix4 (X, Y);
      S : constant Booth_Product := Multiply_Booth_Shift_Register (X, Y);
   begin
      return B = O and then R = O and then S = O;
   end Agree;

   --  Force non-static views of package constants (avoid -gnatwc).
   function OB return Integer is (Operand_Bits);
   function PB return Integer is (Product_Bits);
   function OMin return Integer is (Operand_Min);
   function OMax return Integer is (Operand_Max);
   function PMin return Integer is (Product_Min);
   function PMax return Integer is (Product_Max);

begin
   Ada.Text_IO.Put_Line ("Booth_Multiplication test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ------------------------------------------------------------------
   Section ("1. Constants / bit helpers");
   ------------------------------------------------------------------
   Check (OB = 8, "Operand_Bits = 8");
   Check (PB = 16, "Product_Bits = 16");
   Check (OMin = -128, "Operand_Min = -128");
   Check (OMax = 127, "Operand_Max = 127");
   Check (PMin = -32768, "Product_Min");
   Check (PMax = 32767, "Product_Max");
   Check (PB = 2 * OB, "Product_Bits = 2 * Operand_Bits");
   Check (OMin = -(2 ** (OB - 1)), "Operand_Min formula");
   Check (OMax = (2 ** (OB - 1)) - 1, "Operand_Max formula");
   Check (As_Unsigned (0, 8) = 0, "As_Unsigned 0");
   Check (As_Unsigned (1, 8) = 1, "As_Unsigned 1");
   Check (As_Unsigned (-1, 8) = 255, "As_Unsigned -1");
   Check (As_Unsigned (-128, 8) = 128, "As_Unsigned -128");
   Check (As_Unsigned (127, 8) = 127, "As_Unsigned 127");
   Check (Extract_Bit (5, 0, 8) = 1, "bit0 of 5");
   Check (Extract_Bit (5, 1, 8) = 0, "bit1 of 5");
   Check (Extract_Bit (5, 2, 8) = 1, "bit2 of 5");
   Check (Extract_Bit (-1, 7, 8) = 1, "MSB of -1");
   Check (Extract_Bit (-128, 7, 8) = 1, "MSB of -128");
   Check (Extract_Bit (-128, 0, 8) = 0, "LSB of -128");
   Check (To_Twos_Complement_String (3, 4) = "0011", "str 3/4");
   Check (To_Twos_Complement_String (-4, 4) = "1100", "str -4/4");
   Check (To_Twos_Complement_String (-1, 8) = "11111111", "str -1/8");
   Check (To_Twos_Complement_String (-128, 8) = "10000000", "str -128/8");
   Check (To_Twos_Complement_String (127, 8) = "01111111", "str 127/8");

   ------------------------------------------------------------------
   Section ("2. Wikipedia example 3 x (-4) = -12");
   ------------------------------------------------------------------
   declare
      X : constant Booth_Operand := 3;
      Y : constant Booth_Operand := -4;
      P : Booth_Product;
   begin
      Check (Multiply_Oracle (X, Y) = -12, "oracle 3*(-4)");
      P := Multiply_Booth (X, Y);
      Check (P = -12, "Booth 3*(-4)");
      Check (Multiply_Booth_Radix4 (X, Y) = -12, "radix4 3*(-4)");
      Check (Multiply_Booth_Shift_Register (X, Y) = -12, "shiftreg 3*(-4)");
      Check (To_Twos_Complement_String (Integer (P), 8) = "11110100",
             "product bits -12 (8)");
   end;

   ------------------------------------------------------------------
   Section ("3. Zero / one / minus-one");
   ------------------------------------------------------------------
   Check (Agree (0, 0), "0*0");
   Check (Agree (0, 1), "0*1");
   Check (Agree (1, 0), "1*0");
   Check (Agree (0, -1), "0*(-1)");
   Check (Agree (-1, 0), "(-1)*0");
   Check (Agree (0, 42), "0*42");
   Check (Agree (42, 0), "42*0");
   Check (Agree (0, Booth_Operand'First), "0*Min");
   Check (Agree (Booth_Operand'First, 0), "Min*0");
   Check (Agree (1, 1), "1*1");
   Check (Agree (1, -1), "1*(-1)");
   Check (Agree (-1, 1), "(-1)*1");
   Check (Agree (-1, -1), "(-1)*(-1)");
   Check (Agree (1, 99), "1*99");
   Check (Agree (-1, 99), "(-1)*99");
   Check (Agree (-1, -99), "(-1)*(-99)");
   Check (Agree (-1, Booth_Operand'Last), "(-1)*Max");
   Check (Agree (-1, Booth_Operand'First), "(-1)*Min");

   ------------------------------------------------------------------
   Section ("4. Positives");
   ------------------------------------------------------------------
   Check (Agree (2, 3), "2*3");
   Check (Agree (7, 8), "7*8");
   Check (Agree (12, 12), "12*12");
   Check (Agree (15, 15), "15*15");
   Check (Agree (16, 16), "16*16");
   Check (Agree (25, 4), "25*4");
   Check (Agree (100, 2), "100*2");
   Check (Agree (127, 1), "127*1");
   Check (Agree (127, 2), "127*2");
   Check (Agree (64, 64), "64*64");
   Check (Agree (63, 63), "63*63");
   Check (Agree (Booth_Operand'Last, Booth_Operand'Last), "Max*Max");

   ------------------------------------------------------------------
   Section ("5. Negatives / mixed signs");
   ------------------------------------------------------------------
   Check (Agree (-2, -3), "(-2)*(-3)");
   Check (Agree (-7, -8), "(-7)*(-8)");
   Check (Agree (-12, 5), "(-12)*5");
   Check (Agree (12, -5), "12*(-5)");
   Check (Agree (-100, 2), "(-100)*2");
   Check (Agree (100, -2), "100*(-2)");
   Check (Agree (-64, -64), "(-64)*(-64)");
   Check (Agree (-127, -1), "(-127)*(-1)");
   Check (Agree (-127, 2), "(-127)*2");
   Check (Agree (Booth_Operand'First, 1), "Min*1");
   Check (Agree (Booth_Operand'First, -1), "Min*(-1)");
   Check (Agree (Booth_Operand'First, 2), "Min*2");
   Check (Agree (2, Booth_Operand'First), "2*Min");
   Check (Agree (Booth_Operand'First, Booth_Operand'Last), "Min*Max");
   Check (Agree (Booth_Operand'Last, Booth_Operand'First), "Max*Min");
   Check (Agree (Booth_Operand'First, Booth_Operand'First), "Min*Min");

   ------------------------------------------------------------------
   Section ("6. Alternating / corner bit patterns");
   ------------------------------------------------------------------
   Check (Agree (85, 85), "0x55*0x55");
   Check (Agree (-86, -86), "0xAA*0xAA");
   Check (Agree (85, -86), "0x55*0xAA");
   Check (Agree (-86, 85), "0xAA*0x55");
   Check (Agree (51, 51), "0x33*0x33");
   Check (Agree (-52, -52), "0xCC*0xCC");
   Check (Agree (51, -52), "0x33*0xCC");
   Check (Agree (15, 15), "0x0F*0x0F");
   Check (Agree (-16, -16), "0xF0*0xF0");
   Check (Agree (15, -16), "0x0F*0xF0");
   Check (Agree (7, 1), "7*2^0");
   Check (Agree (7, 2), "7*2^1");
   Check (Agree (7, 4), "7*2^2");
   Check (Agree (7, 8), "7*2^3");
   Check (Agree (7, 16), "7*2^4");
   Check (Agree (7, 32), "7*2^5");
   Check (Agree (7, 64), "7*2^6");
   Check (Agree (7, -128), "7*MSB");
   Check (Agree (-9, 64), "(-9)*2^6");
   Check (Agree (-9, -128), "(-9)*MSB");

   ------------------------------------------------------------------
   Section ("7. Integer overload / Invalid_Argument");
   ------------------------------------------------------------------
   Check (Multiply_Booth (Integer'(3), Integer'(-4)) = Long_Integer'(-12),
          "Integer Booth 3*(-4)");
   Check (Multiply_Booth (Integer'(127), Integer'(127)) = Long_Integer'(16_129),
          "Integer Booth Max*Max");
   Check (Multiply_Booth (Integer'(-128), Integer'(-128)) = Long_Integer'(16_384),
          "Integer Booth Min*Min");
   declare
      Raised : Boolean := False;
      Unused : Long_Integer;
      pragma Unreferenced (Unused);
   begin
      begin
         Unused := Multiply_Booth (Integer'(128), Integer'(1));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Integer Booth X out of range");

      Raised := False;
      begin
         Unused := Multiply_Booth (Integer'(1), Integer'(-129));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Integer Booth Y out of range");
   end;

   ------------------------------------------------------------------
   Section ("8. Exhaustive vs oracle (all 8-bit pairs)");
   ------------------------------------------------------------------
   declare
      Failures : Natural := 0;
   begin
      for Xi in Booth_Operand'Range loop
         for Yi in Booth_Operand'Range loop
            if Multiply_Booth (Xi, Yi) /= Multiply_Oracle (Xi, Yi) then
               Failures := Failures + 1;
            end if;
         end loop;
      end loop;
      Check (Failures = 0, "exhaustive classic Booth vs oracle");

      Failures := 0;
      for Xi in Booth_Operand'Range loop
         for Yi in Booth_Operand'Range loop
            if Multiply_Booth_Radix4 (Xi, Yi) /= Multiply_Oracle (Xi, Yi)
            then
               Failures := Failures + 1;
            end if;
         end loop;
      end loop;
      Check (Failures = 0, "exhaustive radix-4 vs oracle");

      Failures := 0;
      for Xi in Booth_Operand'Range loop
         for Yi in Booth_Operand'Range loop
            if Multiply_Booth_Shift_Register (Xi, Yi)
              /= Multiply_Oracle (Xi, Yi)
            then
               Failures := Failures + 1;
            end if;
         end loop;
      end loop;
      Check (Failures = 0, "exhaustive shift-register vs oracle");

      Check (Agree (Booth_Operand'First, Booth_Operand'Last), "spot Min*Max");
      Check (Agree (37, -91), "spot 37*(-91)");
      Check (Agree (-55, -55), "spot (-55)*(-55)");
      Check (Agree (1, Booth_Operand'First), "spot 1*Min");
   end;

   ------------------------------------------------------------------
   Section ("9. Cross-check algorithms pairwise");
   ------------------------------------------------------------------
   declare
      Samples : constant array (Positive range <>) of Booth_Operand :=
        [0, 1, -1, 2, -2, 7, -7, 15, -16, 42, -42,
         85, -86, 127, -128, 64, -64, 100, -100, 51, -52];
      All_Ok : Boolean := True;
   begin
      for I in Samples'Range loop
         for J in Samples'Range loop
            if not Agree (Samples (I), Samples (J)) then
               All_Ok := False;
            end if;
         end loop;
      end loop;
      Check (All_Ok, "sample grid classic=radix4=shift=oracle");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Natural'Image (Pass_Count) & " passed,"
     & Natural'Image (Fail_Count) & " failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
