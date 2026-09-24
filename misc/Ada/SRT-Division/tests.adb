--  Standalone test suite for SRT_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with SRT_Division; use SRT_Division;

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

   function OB return Integer is (Operand_Bits);
   function OMin return Integer is (Operand_Min);
   function OMax return Integer is (Operand_Max);

   function Agree (N, D : SRT_Operand) return Boolean is
      S : constant Division_Result := Divide_SRT (N, D);
      O : constant Division_Result := Divide_Oracle (N, D);
   begin
      return S.Quotient = O.Quotient
        and then S.Remainder = O.Remainder
        and then Integer (N) =
                   Integer (S.Quotient) * Integer (D) + Integer (S.Remainder);
   end Agree;

   function Image (V : Integer) return String is
   begin
      return Integer'Image (V);
   end Image;

begin
   Ada.Text_IO.Put_Line ("SRT_Division test suite");
   Ada.Text_IO.Put_Line ("=======================");

   ------------------------------------------------------------------
   Section ("1. Constants / bit helpers");
   ------------------------------------------------------------------
   Check (OB = 8, "Operand_Bits = 8");
   Check (OMin = -128, "Operand_Min = -128");
   Check (OMax = 127, "Operand_Max = 127");
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
   Check (To_Twos_Complement_String (13, 8) = "00001101", "str 13/8");
   Check (To_Twos_Complement_String (-4, 4) = "1100", "str -4/4");
   Check (To_Twos_Complement_String (-1, 8) = "11111111", "str -1/8");

   ------------------------------------------------------------------
   Section ("2. Select_Quotient_Digit / Convert_Redundant_Quotient");
   ------------------------------------------------------------------
   Check (Select_Quotient_Digit (0, 10) = 0, "SEL 0 vs 10 -> 0");
   Check (Select_Quotient_Digit (5, 10) = 1, "SEL 5 vs 10 -> 1 (ceil half=5)");
   Check (Select_Quotient_Digit (4, 10) = 0, "SEL 4 vs 10 -> 0");
   Check (Select_Quotient_Digit (-5, 10) = -1, "SEL -5 vs 10 -> -1");
   Check (Select_Quotient_Digit (-4, 10) = 0, "SEL -4 vs 10 -> 0");
   Check (Select_Quotient_Digit (100, 3) = 1, "SEL large positive");
   Check (Select_Quotient_Digit (-100, 3) = -1, "SEL large negative");
   declare
      Digs : constant Quotient_Digit_Array := [1, 0, -1, 1];
      --  1*8 + 0*4 + (-1)*2 + 1 = 8 - 2 + 1 = 7
   begin
      Check (Convert_Redundant_Quotient (Digs) = 7, "convert 1,0,-1,1 -> 7");
   end;
   declare
      Digs : constant Quotient_Digit_Array := [0, 0, 1, 0];
   begin
      Check (Convert_Redundant_Quotient (Digs) = 2, "convert 0,0,1,0 -> 2");
   end;

   ------------------------------------------------------------------
   Section ("3. Hand examples vs oracle");
   ------------------------------------------------------------------
   declare
      R : Division_Result;
   begin
      R := Divide_SRT (SRT_Operand (13), SRT_Operand (3));
      Check (R.Quotient = 4 and then R.Remainder = 1, "13/3 = 4 rem 1");
      Check (Agree (13, 3), "13/3 agree oracle");

      R := Divide_SRT (SRT_Operand (0), SRT_Operand (5));
      Check (R.Quotient = 0 and then R.Remainder = 0, "0/5 = 0 rem 0");

      R := Divide_SRT (SRT_Operand (7), SRT_Operand (1));
      Check (R.Quotient = 7 and then R.Remainder = 0, "7/1 = 7 rem 0");

      R := Divide_SRT (SRT_Operand (7), SRT_Operand (7));
      Check (R.Quotient = 1 and then R.Remainder = 0, "7/7 = 1 rem 0");

      R := Divide_SRT (SRT_Operand (7), SRT_Operand (8));
      Check (R.Quotient = 0 and then R.Remainder = 7, "7/8 = 0 rem 7");

      R := Divide_SRT (SRT_Operand (-13), SRT_Operand (3));
      Check (R.Quotient = -4 and then R.Remainder = -1, "-13/3 trunc");
      Check (Agree (-13, 3), "-13/3 agree");

      R := Divide_SRT (SRT_Operand (13), SRT_Operand (-3));
      Check (R.Quotient = -4 and then R.Remainder = 1, "13/(-3) trunc");
      Check (Agree (13, -3), "13/(-3) agree");

      R := Divide_SRT (SRT_Operand (-13), SRT_Operand (-3));
      Check (R.Quotient = 4 and then R.Remainder = -1, "(-13)/(-3) trunc");
      Check (Agree (-13, -3), "(-13)/(-3) agree");

      R := Divide_SRT (SRT_Operand (-128), SRT_Operand (2));
      Check (R.Quotient = -64 and then R.Remainder = 0, "-128/2");
      Check (Agree (-128, 2), "-128/2 agree");

      R := Divide_SRT (SRT_Operand (127), SRT_Operand (2));
      Check (R.Quotient = 63 and then R.Remainder = 1, "127/2");
   end;

   ------------------------------------------------------------------
   Section ("4. Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      R      : Division_Result;
      pragma Unreferenced (R);
   begin
      begin
         R := Divide_SRT (SRT_Operand (1), SRT_Operand (0));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "D=0 raises Invalid_Argument");
   end;
   declare
      Raised : Boolean := False;
      R      : Division_Result;
      pragma Unreferenced (R);
   begin
      begin
         R := Divide_SRT (Integer'(1), Integer'(0));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Integer D=0 raises");
   end;
   declare
      Raised : Boolean := False;
      R      : Division_Result;
      pragma Unreferenced (R);
   begin
      begin
         R := Divide_SRT (SRT_Operand'First, SRT_Operand (-1));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Operand_Min/(-1) overflow raises");
   end;
   declare
      Raised : Boolean := False;
      R      : Division_Result;
      pragma Unreferenced (R);
   begin
      begin
         R := Divide_SRT (Integer'(200), Integer'(3));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Integer out of range raises");
   end;

   ------------------------------------------------------------------
   Section ("5. Unsigned core digit trace (13/3)");
   ------------------------------------------------------------------
   declare
      Q, R : Natural;
      Digs : Quotient_Digit_Array (0 .. 7);
      Conv : Long_Integer;
   begin
      Divide_SRT_Unsigned (13, 3, 8, Q, R, Digs);
      Check (Q = 4 and then R = 1, "unsigned 13/3");
      Conv := Convert_Redundant_Quotient (Digs);
      --  After correction Q may differ from raw conversion by ±1
      Check (Conv = Long_Integer (Q)
             or else Conv = Long_Integer (Q) + 1
             or else Conv = Long_Integer (Q) - 1,
             "raw redundant near corrected Q");
      Check (13 = Integer (Q) * 3 + Integer (R), "unsigned identity");
   end;

   ------------------------------------------------------------------
   Section ("6. Exhaustive grid vs oracle (skip Min/-1)");
   ------------------------------------------------------------------
   declare
      Failures : Natural := 0;
      Checks   : Natural := 0;
   begin
      for Ni in Operand_Min .. Operand_Max loop
         for Di in Operand_Min .. Operand_Max loop
            if Di /= 0
              and then not (Ni = Operand_Min and then Di = -1)
            then
               Checks := Checks + 1;
               if not Agree (SRT_Operand (Ni), SRT_Operand (Di)) then
                  Failures := Failures + 1;
                  if Failures <= 5 then
                     Ada.Text_IO.Put_Line
                       ("  mismatch N=" & Image (Ni) & " D=" & Image (Di));
                  end if;
               end if;
            end if;
         end loop;
      end loop;
      Check (Failures = 0,
             "exhaustive 8-bit grid vs oracle (failures=0)");
      Check (Checks = 256 * 255 - 1,
             "exhaustive pair count 256*255-1");
   end;

   ------------------------------------------------------------------
   Section ("7. Sampled identity N = Q D + R");
   ------------------------------------------------------------------
   declare
      Samples : constant array (Positive range <>) of
        SRT_Operand := [0, 1, -1, 2, -2, 17, -17, 100, -100, 127, -127, -128];
      Ok : Boolean := True;
   begin
      for N of Samples loop
         for D of Samples loop
            if D /= 0
              and then not (N = SRT_Operand'First and then D = -1)
            then
               if not Agree (N, D) then
                  Ok := False;
               end if;
            end if;
         end loop;
      end loop;
      Check (Ok, "sampled pairs all agree");
   end;

   ------------------------------------------------------------------
   Section ("8. Integer convenience overload");
   ------------------------------------------------------------------
   declare
      R : Division_Result;
   begin
      R := Divide_SRT (Integer'(20), Integer'(6));
      Check (R.Quotient = 3 and then R.Remainder = 2, "Integer 20/6");
      R := Divide_SRT (Integer'(-20), Integer'(6));
      Check (R.Quotient = -3 and then R.Remainder = -2, "Integer -20/6");
      R := Divide_Oracle (SRT_Operand (20), SRT_Operand (6));
      Check (R.Quotient = 3 and then R.Remainder = 2, "oracle 20/6");
   end;

   ------------------------------------------------------------------
   Section ("9. D = ±1 and zero dividend sweep");
   ------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      R  : Division_Result;
   begin
      for N in SRT_Operand'Range loop
         if not Agree (N, 1) then
            Ok := False;
         end if;
         if N /= SRT_Operand'First and then not Agree (N, -1) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all N / ±1 agree (skip Min/-1)");
      Ok := True;
      for D in SRT_Operand'Range loop
         if D /= 0 then
            R := Divide_SRT (SRT_Operand (0), D);
            if R.Quotient /= 0 or else R.Remainder /= 0 then
               Ok := False;
            end if;
         end if;
      end loop;
      Check (Ok, "0 / D = 0 rem 0 for all D /= 0");
   end;

   ------------------------------------------------------------------
   Section ("10. More oracle pairs (positives)");
   ------------------------------------------------------------------
   declare
      type Pair is record
         N, D, Q, R : Integer;
      end record;
      Cases : constant array (Positive range <>) of Pair :=
        [(1, 1, 1, 0), (2, 1, 2, 0), (3, 2, 1, 1), (10, 3, 3, 1),
         (100, 7, 14, 2), (127, 3, 42, 1), (127, 127, 1, 0),
         (64, 8, 8, 0), (63, 8, 7, 7), (50, 6, 8, 2),
         (99, 10, 9, 9), (81, 9, 9, 0), (16, 5, 3, 1),
         (25, 4, 6, 1), (48, 7, 6, 6)];
      R : Division_Result;
      Ok : Boolean := True;
   begin
      for C of Cases loop
         R := Divide_SRT (SRT_Operand (C.N), SRT_Operand (C.D));
         if Integer (R.Quotient) /= C.Q
           or else Integer (R.Remainder) /= C.R
           or else not Agree (SRT_Operand (C.N), SRT_Operand (C.D))
         then
            Ok := False;
            Ada.Text_IO.Put_Line
              ("  bad " & Image (C.N) & "/" & Image (C.D));
         end if;
         Check
           (Integer (R.Quotient) = C.Q
            and then Integer (R.Remainder) = C.R,
            "pair" & Image (C.N) & "/" & Image (C.D));
      end loop;
      Check (Ok, "all positive table pairs ok");
   end;

   ------------------------------------------------------------------
   Section ("11. More oracle pairs (signed)");
   ------------------------------------------------------------------
   declare
      type Pair is record
         N, D, Q, R : Integer;
      end record;
      Cases : constant array (Positive range <>) of Pair :=
        [(-10, 3, -3, -1), (10, -3, -3, 1), (-10, -3, 3, -1),
         (-7, 2, -3, -1), (7, -2, -3, 1), (-7, -2, 3, -1),
         (-100, 9, -11, -1), (100, -9, -11, 1), (-100, -9, 11, -1),
         (-127, 2, -63, -1), (127, -2, -63, 1), (-128, 4, -32, 0),
         (-128, 5, -25, -3), (1, -1, -1, 0), (-1, 1, -1, 0)];
      R : Division_Result;
   begin
      for C of Cases loop
         R := Divide_SRT (SRT_Operand (C.N), SRT_Operand (C.D));
         Check
           (Integer (R.Quotient) = C.Q
            and then Integer (R.Remainder) = C.R
            and then Agree (SRT_Operand (C.N), SRT_Operand (C.D)),
            "signed" & Image (C.N) & "/" & Image (C.D));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("12. Select / convert edge cases");
   ------------------------------------------------------------------
   Check (Select_Quotient_Digit (1, 1) = 1, "SEL 1 vs 1");
   Check (Select_Quotient_Digit (0, 1) = 0, "SEL 0 vs 1");
   Check (Select_Quotient_Digit (-1, 1) = -1, "SEL -1 vs 1");
   Check (Select_Quotient_Digit (2, 5) = 0, "SEL 2 vs 5 (half=3)");
   Check (Select_Quotient_Digit (3, 5) = 1, "SEL 3 vs 5");
   Check (Select_Quotient_Digit (-3, 5) = -1, "SEL -3 vs 5");
   declare
      A : constant Quotient_Digit_Array := [1, 1, 1, 1];
      B : constant Quotient_Digit_Array := [-1, 0, 0, 0];
      C : constant Quotient_Digit_Array := [0, 0, 0, 0];
      D : constant Quotient_Digit_Array := [1, -1, 1, -1];
   begin
      Check (Convert_Redundant_Quotient (A) = 15, "convert 1111 -> 15");
      Check (Convert_Redundant_Quotient (B) = -8, "convert -1000 -> -8");
      Check (Convert_Redundant_Quotient (C) = 0, "convert 0000 -> 0");
      Check (Convert_Redundant_Quotient (D) = 5, "convert 1-11-1 -> 5");
   end;

   ------------------------------------------------------------------
   Section ("13. Unsigned Width variants");
   ------------------------------------------------------------------
   declare
      Q, R : Natural;
      Dig4 : Quotient_Digit_Array (0 .. 3);
      Dig8 : Quotient_Digit_Array (0 .. 7);
   begin
      Divide_SRT_Unsigned (13, 3, 8, Q, R, Dig8);
      Check (Q = 4 and then R = 1, "W8 13/3 again");
      Divide_SRT_Unsigned (7, 2, 4, Q, R, Dig4);
      Check (Q = 3 and then R = 1, "W4 7/2");
      Divide_SRT_Unsigned (0, 9, 8, Q, R, Dig8);
      Check (Q = 0 and then R = 0, "W8 0/9");
      Divide_SRT_Unsigned (255, 16, 8, Q, R, Dig8);
      Check (Q = 15 and then R = 15, "W8 255/16");
      Divide_SRT_Unsigned (128, 128, 8, Q, R, Dig8);
      Check (Q = 1 and then R = 0, "W8 128/128");
   end;

   ------------------------------------------------------------------
   Section ("14. Bit-string round trips");
   ------------------------------------------------------------------
   Check (To_Twos_Complement_String (0, 8) = "00000000", "str 0");
   Check (To_Twos_Complement_String (1, 8) = "00000001", "str 1");
   Check (To_Twos_Complement_String (42, 8) = "00101010", "str 42");
   Check (To_Twos_Complement_String (-42, 8) = "11010110", "str -42");
   Check (To_Twos_Complement_String (127, 8) = "01111111", "str 127");
   Check (Extract_Bit (42, 1, 8) = 1, "bit1 of 42");
   Check (Extract_Bit (42, 3, 8) = 1, "bit3 of 42");
   Check (Extract_Bit (42, 5, 8) = 1, "bit5 of 42");
   Check (Extract_Bit (42, 7, 8) = 0, "bit7 of 42");

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=======================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
